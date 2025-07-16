//
//  NetworkManager.swift
//  TestDemo
//
//  Created by maliangliang on 2025/7/16.
//

import Foundation
import Alamofire

// MARK: - HTTP方法枚举
public enum SNHTTPMethod {
    case get
    case post
    case put
    case delete
    case patch
    case head
    case options
    
    var alamofireMethod: HTTPMethod {
        switch self {
        case .get: return .get
        case .post: return .post
        case .put: return .put
        case .delete: return .delete
        case .patch: return .patch
        case .head: return .head
        case .options: return .options
        }
    }
}

// MARK: - 参数编码类型
public enum SNParameterEncoding {
    case json
    case url
    
    var alamofireEncoding: ParameterEncoding {
        switch self {
        case .json: return JSONEncoding.default
        case .url: return URLEncoding.default
        }
    }
}

// MARK: - 业务拦截器配置
/// 业务拦截器，可以拦截包含特定业务码的响应，无论HTTP状态码是成功(2xx)还是失败(非2xx)。
public struct SNBusinessInterceptor {
    let businessCode: String
    let interceptHandler: (Any) -> Void
    
    public init(businessCode: String, interceptHandler: @escaping (Any) -> Void) {
        self.businessCode = businessCode
        self.interceptHandler = interceptHandler
    }
}

// MARK: - 网络配置
public struct SNNetworkConfiguration {
    var baseURL: String
    var defaultHeaders: [String: String]
    var defaultParameters: [String: Any]
    var enableLogging: Bool
    var timeout: TimeInterval
    var businessInterceptors: [SNBusinessInterceptor]
    var businessCodeKeyPath: String // 业务码在响应中的key路径，如"code"或"data.code"
    
    public init(
        baseURL: String = "",
        defaultHeaders: [String: String] = [:],
        defaultParameters: [String: Any] = [:],
        enableLogging: Bool = true,
        timeout: TimeInterval = 30,
        businessInterceptors: [SNBusinessInterceptor] = [],
        businessCodeKeyPath: String = "code"
    ) {
        self.baseURL = baseURL
        self.defaultHeaders = defaultHeaders
        self.defaultParameters = defaultParameters
        self.enableLogging = enableLogging
        self.timeout = timeout
        self.businessInterceptors = businessInterceptors
        self.businessCodeKeyPath = businessCodeKeyPath
    }
}

// MARK: - HTTPS证书配置
public enum SNSSLConfiguration {
    case none
    case singleWay(serverTrust: SecTrust?)
    case doubleWay(clientCertificate: SecCertificate, clientKey: SecKey)
    
    func configure(for session: Session) -> Session {
        // 注意: SSL/TLS固定(Pinning)和客户端证书的实现比较复杂,
        // 此处为简化示例。实际生产环境中需要仔细处理证书和信任评估器。
        switch self {
        case .none:
            // 使用默认的Session配置
            let configuration = URLSessionConfiguration.default
            return Session(configuration: configuration)
        case .singleWay(let serverTrust):
            // 此处应配置ServerTrustManager来验证服务器证书
            // 示例: let trustManager = ServerTrustManager(evaluators: ["your.host.com": PinnedCertificatesTrustEvaluator()])
            // 为了代码能跑通，此处用一个简单的manager，实际应替换为真实配置
            let trustManager = ServerTrustManager(allHostsMustBeEvaluated: false, evaluators: [:])
            let configuration = URLSessionConfiguration.default
            return Session(configuration: configuration, serverTrustManager: trustManager)
        case .doubleWay(let clientCertificate, let clientKey):
            // 此处应配置客户端证书
            // let identity = SecIdentity...
            // let trustManager = ServerTrustManager(...)
            // let authenticator = CertificateAuthenticator(certificates: [identity])
            // return Session(..., serverTrustManager: trustManager, authenticator: authenticator)
            // 同样，此处为简化示例
            return Session.default
        }
    }
}

// MARK: - 回调类型
public typealias SNProgressHandler = (Double) -> Void // 进度百分比 0.0-1.0
public typealias SNUploadProgressHandler = (Double) -> Void
public typealias SNDownloadProgressHandler = (Double) -> Void
public typealias SNSuccessHandler<T> = (T) -> Void
public typealias SNFailureHandler = (Error) -> Void
public typealias SNJSONResponseHandler = (String) -> Void

// MARK: - 网络请求任务协议
public protocol SNRequestTask {
    func cancel()
    func suspend()
    func resume()
}

// MARK: - 网络请求任务实现
private class SNRequestTaskImpl: SNRequestTask {
    private let request: Request
    
    init(request: Request) {
        self.request = request
    }
    
    func cancel() {
        request.cancel()
    }
    
    func suspend() {
        request.suspend()
    }
    
    func resume() {
        request.resume()
    }
}

// MARK: - 文件上传数据
public struct SNUploadData {
    let data: Data
    let name: String
    let fileName: String
    let mimeType: String
    
    public init(data: Data, name: String, fileName: String, mimeType: String) {
        self.data = data
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
    }
}

// MARK: - 主要的网络管理器
public class SNNetworkManager {
    
    // MARK: - 单例
    public static let shared = SNNetworkManager()
    
    // MARK: - 私有属性
    private var session: Session
    private var configuration: SNNetworkConfiguration
    private var sslConfiguration: SNSSLConfiguration = .none
    
    // MARK: - 初始化
    private init() {
        self.configuration = SNNetworkConfiguration()
        self.session = Session.default
        setupSession()
    }
    
    // MARK: - 配置方法
    public func configure(with config: SNNetworkConfiguration) {
        self.configuration = config
        setupSession()
    }
    
    public func configureSSL(with sslConfig: SNSSLConfiguration) {
        self.sslConfiguration = sslConfig
        self.session = sslConfig.configure(for: self.session)
    }
    
    // MARK: - 设置Session
    private func setupSession() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = self.configuration.timeout
        configuration.timeoutIntervalForResource = self.configuration.timeout
        
        self.session = Session(configuration: configuration)
    }
    
    // MARK: - 通用请求方法
    @discardableResult
    public func request<T: Codable>(
        _ url: String,
        method: SNHTTPMethod = .get,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        baseURL: String? = nil,
        encoding: SNParameterEncoding = .json,
        success: @escaping SNSuccessHandler<T>,
        failure: @escaping SNFailureHandler
    ) -> SNRequestTask {
        
        let finalURL = buildURL(url, baseURL: baseURL)
        let finalHeaders = buildHeaders(headers)
        let finalParameters = buildParameters(parameters)
        
        logRequest(url: finalURL, method: method, parameters: finalParameters, headers: finalHeaders)
        
        let request = session.request(
            finalURL,
            method: method.alamofireMethod,
            parameters: finalParameters,
            encoding: encoding.alamofireEncoding,
            headers: HTTPHeaders(finalHeaders)
        ).responseData { [weak self] response in
            // 将所有响应处理逻辑集中到 handleResponse 中
            self?.handleResponse(response: response, success: success, failure: failure)
        }
        
        return SNRequestTaskImpl(request: request)
    }
    
    // MARK: - JSON字符串响应方法
    @discardableResult
    public func requestJSON(
        _ url: String,
        method: SNHTTPMethod = .get,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        baseURL: String? = nil,
        encoding: SNParameterEncoding = .json,
        success: @escaping SNJSONResponseHandler,
        failure: @escaping SNFailureHandler
    ) -> SNRequestTask {
        
        let finalURL = buildURL(url, baseURL: baseURL)
        let finalHeaders = buildHeaders(headers)
        let finalParameters = buildParameters(parameters)
        
        logRequest(url: finalURL, method: method, parameters: finalParameters, headers: finalHeaders)
        
        let request = session.request(
            finalURL,
            method: method.alamofireMethod,
            parameters: finalParameters,
            encoding: encoding.alamofireEncoding,
            headers: HTTPHeaders(finalHeaders)
        ).responseString { [weak self] response in
            self?.handleJSONResponse(response: response, success: success, failure: failure)
        }
        
        return SNRequestTaskImpl(request: request)
    }
    
    // MARK: - 多部分上传方法
    @discardableResult
    public func uploadMultipart<T: Codable>(
        _ url: String,
        files: [SNUploadData],
        parameters: [String: Any]? = nil,
        method: SNHTTPMethod = .post,
        headers: [String: String]? = nil,
        baseURL: String? = nil,
        progressHandler: SNUploadProgressHandler? = nil,
        success: @escaping SNSuccessHandler<T>,
        failure: @escaping SNFailureHandler
    ) -> SNRequestTask {
        
        let finalURL = buildURL(url, baseURL: baseURL)
        let finalHeaders = buildHeaders(headers)
        let finalParameters = buildParameters(parameters)
        
        logRequest(url: finalURL, method: method, parameters: finalParameters, headers: finalHeaders)
        
        let request = session.upload(
            multipartFormData: { multipartFormData in
                // 添加文件
                for file in files {
                    multipartFormData.append(file.data, withName: file.name, fileName: file.fileName, mimeType: file.mimeType)
                }
                
                // 添加参数
                for (key, value) in finalParameters {
                    if let data = "\(value)".data(using: .utf8) {
                        multipartFormData.append(data, withName: key)
                    }
                }
            },
            to: finalURL,
            method: method.alamofireMethod,
            headers: HTTPHeaders(finalHeaders)
        ).uploadProgress { progress in
            progressHandler?(progress.fractionCompleted)
        }.responseData { [weak self] response in
            self?.handleResponse(response: response, success: success, failure: failure)
        }
        
        return SNRequestTaskImpl(request: request)
    }
    
    // MARK: - 下载方法
    @discardableResult
    public func download(
        _ url: String,
        method: SNHTTPMethod = .get,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        baseURL: String? = nil,
        destinationURL: URL? = nil,
        progressHandler: SNDownloadProgressHandler? = nil,
        success: @escaping (URL) -> Void,
        failure: @escaping SNFailureHandler
    ) -> SNRequestTask {
        
        let finalURL = buildURL(url, baseURL: baseURL)
        let finalHeaders = buildHeaders(headers)
        let finalParameters = buildParameters(parameters)
        
        logRequest(url: finalURL, method: method, parameters: finalParameters, headers: finalHeaders)
        
        let destination: DownloadRequest.Destination?
        if let destinationURL {
            destination = { _, _ in
                return (destinationURL, [.removePreviousFile, .createIntermediateDirectories])
            }
        } else {
            destination = nil
        }
        
        let request = session.download(
            finalURL,
            method: method.alamofireMethod,
            parameters: finalParameters,
            headers: HTTPHeaders(finalHeaders),
            to: destination
        ).downloadProgress { progress in
            progressHandler?(progress.fractionCompleted)
        }
            .response { [weak self] response in
                self?.logResponse(response: response)
                
                // 下载请求不经过业务拦截器，直接处理结果
                switch response.result {
                case .success(let url):
                    if let url {
                        success(url)
                    } else {
                        failure(SNNetworkError.noData)
                    }
                case .failure(let error):
                    failure(error)
                }
            }
        
        return SNRequestTaskImpl(request: request)
    }
    
    // MARK: - 私有辅助方法
    private func buildURL(_ url: String, baseURL: String?) -> String {
        let base = baseURL ?? configuration.baseURL
        if url.hasPrefix("http://") || url.hasPrefix("https://") {
            return url
        }
        if base.isEmpty {
            return url
        }
        let cleanBase = base.hasSuffix("/") ? String(base.dropLast()) : base
        let cleanURL = url.hasPrefix("/") ? String(url.dropFirst()) : url
        return "\(cleanBase)/\(cleanURL)"
    }
    
    private func buildHeaders(_ headers: [String: String]?) -> [String: String] {
        var finalHeaders = configuration.defaultHeaders
        headers?.forEach { finalHeaders[$0.key] = $0.value }
        return finalHeaders
    }
    
    private func buildParameters(_ parameters: [String: Any]?) -> [String: Any] {
        var finalParameters = configuration.defaultParameters
        parameters?.forEach { finalParameters[$0.key] = $0.value }
        return finalParameters
    }
    
    private func handleResponse<T: Codable>(
        response: AFDataResponse<Data>,
        success: @escaping SNSuccessHandler<T>,
        failure: @escaping SNFailureHandler
    ) {
        logResponse(response: response)
        
        // 1. 检查底层网络错误 (例如无网络连接)
        if let afError = response.error, response.response == nil {
            failure(afError)
            return
        }
        
        // 2. 只要有响应数据(data)，就优先进行业务拦截检查
        if let data = response.data, !data.isEmpty {
            if checkBusinessInterceptors(data: data) {
                // 拦截器已处理，流程结束
                return
            }
        }
        
        // 3. 检查HTTP状态码
        guard let httpResponse = response.response, (200..<300).contains(httpResponse.statusCode) else {
            let error = SNNetworkError.httpError(
                statusCode: response.response?.statusCode ?? -1,
                data: response.data
            )
            failure(error)
            return
        }
        
        // 4. 检查响应数据是否存在
        guard let data = response.data, !data.isEmpty else {
            failure(SNNetworkError.noData)
            return
        }
        
        // 5. 解码并返回成功
        do {
            let result = try JSONDecoder().decode(T.self, from: data)
            success(result)
        } catch {
            failure(SNNetworkError.decodingError(error))
        }
    }
    
    private func handleJSONResponse(
        response: AFDataResponse<String>,
        success: @escaping SNJSONResponseHandler,
        failure: @escaping SNFailureHandler
    ) {
        logResponse(response: response)
        
        if let afError = response.error, response.response == nil {
            failure(afError)
            return
        }
        
        if let data = response.data, !data.isEmpty {
            if checkBusinessInterceptors(data: data) {
                return
            }
        }
        
        guard let httpResponse = response.response, (200..<300).contains(httpResponse.statusCode) else {
            let error = SNNetworkError.httpError(
                statusCode: response.response?.statusCode ?? -1,
                data: response.data
            )
            failure(error)
            return
        }
        
        switch response.result {
        case .success(let jsonString):
            success(jsonString)
        case .failure(let error):
            // 理论上，前面的检查已经覆盖了大部分情况，但为了健壮性保留
            failure(error)
        }
    }
    
    private func checkBusinessInterceptors(data: Data) -> Bool {
        guard !configuration.businessInterceptors.isEmpty else { return false }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            
            for interceptor in configuration.businessInterceptors {
                if let businessCode = getValueFromKeyPath(json, keyPath: configuration.businessCodeKeyPath) {
                    let codeString = "\(businessCode)"
                    if codeString == interceptor.businessCode {
                        DispatchQueue.main.async { // 确保UI操作等在主线程
                            interceptor.interceptHandler(json)
                        }
                        return true // 拦截成功，中断后续流程
                    }
                }
            }
        } catch {
            if configuration.enableLogging {
                print("📦 [SNNetwork] Interceptor: Failed to parse JSON for interception. Error: \(error)")
            }
        }
        
        return false
    }
    
    private func getValueFromKeyPath(_ object: Any, keyPath: String) -> Any? {
        let keys = keyPath.split(separator: ".").map(String.init)
        var current: Any? = object
        
        for key in keys {
            if let dict = current as? [String: Any] {
                current = dict[key]
            } else {
                return nil
            }
        }
        return current
    }
    
    
    private func logRequest(url: String, method: SNHTTPMethod, parameters: [String: Any]?, headers: [String: String]) {
        guard configuration.enableLogging else { return }
        
        print("🚀 [SNNetwork] Request Start")
        print("   URL: \(url)")
        print("   Method: \(method.alamofireMethod.rawValue)")
        if let parameters, !parameters.isEmpty {
            print("   Parameters: \(parameters)")
        }
        if !headers.isEmpty {
            print("   Headers: \(headers)")
        }
        print("---------------------------------")
    }
    
    // MARK: - 现有日志函数 (用于DataResponse)
    private func logResponse<T>(response: AFDataResponse<T>) {
        guard configuration.enableLogging else { return }
        
        print("📦 [SNNetwork] Response Received")
        if let url = response.request?.url?.absoluteString {
            print("   URL: \(url)")
        }
        if let statusCode = response.response?.statusCode {
            print("   StatusCode: \(statusCode)")
        }
        
        switch response.result {
        case .success:
            if let data = response.data, let string = String(data: data, encoding: .utf8) {
                print("   Response Body:\n\(string)")
            } else {
                print("   Response contains no readable data.")
            }
        case .failure(let error):
            print("   Error: \(error.localizedDescription)")
            if let data = response.data, let string = String(data: data, encoding: .utf8) {
                print("   Error Response Body:\n\(string)")
            }
        }
        print("---------------------------------")
    }
    
    // MARK: - 新增的日志函数 (用于DownloadResponse)
    /// 通过函数重载，为下载请求提供专门的日志记录
    private func logResponse(response: AFDownloadResponse<URL?>) {
        guard configuration.enableLogging else { return }
        
        print("📦 [SNNetwork] Download Response Received")
        if let url = response.request?.url?.absoluteString {
            print("   URL: \(url)")
        }
        if let statusCode = response.response?.statusCode {
            print("   StatusCode: \(statusCode)")
        }
        
        switch response.result {
        case .success(let destinationUrl):
            if let path = destinationUrl?.path {
                print("   File saved to: \(path)")
            } else {
                print("   Download successful, but destination URL is nil.")
            }
        case .failure(let error):
            print("   Download Error: \(error.localizedDescription)")
        }
        print("---------------------------------")
    }
}

// MARK: - 网络错误枚举
public enum SNNetworkError: Error {
    case invalidResponse
    case noData
    case decodingError(Error)
    case httpError(statusCode: Int, data: Data?)
    
    public var localizedDescription: String {
        switch self {
        case .invalidResponse:
            return "Invalid response from server."
        case .noData:
            return "No data received from server."
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .httpError(let statusCode, _):
            return "HTTP request failed with status code: \(statusCode)"
        }
    }
}


// MARK: - 扩展方法
extension SNNetworkManager {
    
    public func addBusinessInterceptor(_ interceptor: SNBusinessInterceptor) {
        configuration.businessInterceptors.append(interceptor)
    }
    
    public func removeBusinessInterceptor(for businessCode: String) {
        configuration.businessInterceptors.removeAll { $0.businessCode == businessCode }
    }
    
    public func clearBusinessInterceptors() {
        configuration.businessInterceptors.removeAll()
    }
    
    public func updateDefaultParameters(_ parameters: [String: Any]) {
        configuration.defaultParameters = parameters
    }
    
    public func addDefaultParameter(key: String, value: Any) {
        configuration.defaultParameters[key] = value
    }
    
    public func removeDefaultParameter(key: String) {
        configuration.defaultParameters.removeValue(forKey: key)
    }
    
    public func updateDefaultHeaders(_ headers: [String: String]) {
        configuration.defaultHeaders = headers
    }
    
    public func addDefaultHeader(key: String, value: String) {
        configuration.defaultHeaders[key] = value
    }
    
    public func removeDefaultHeader(key: String) {
        configuration.defaultHeaders.removeValue(forKey: key)
    }
    
    public func updateBaseURL(_ baseURL: String) {
        configuration.baseURL = baseURL
    }
    
    public func setLoggingEnabled(_ enabled: Bool) {
        configuration.enableLogging = enabled
    }
    
    public func setTimeout(_ timeout: TimeInterval) {
        configuration.timeout = timeout
        setupSession()
    }
    
    public func cancelAllRequests() {
        session.cancelAllRequests()
    }
}

// MARK: - 使用示例
/*
 // 1. 配置网络管理器
 let config = SNNetworkConfiguration(
 baseURL: "https://api.example.com",
 defaultHeaders: [
 "Content-Type": "application/json",
 "Authorization": "Bearer token"
 ],
 defaultParameters: [
 "version": "1.0",
 "platform": "ios"
 ],
 enableLogging: true,
 businessCodeKeyPath: "code"
 )
 
 // 2. 添加业务拦截器
 let interceptor = SNBusinessInterceptor(businessCode: "401") { response in
 // 处理401错误，比如跳转到登录页
 print("需要重新登录")
 }
 
 // 3. 配置管理器
 SNNetworkManager.shared.configure(with: config)
 SNNetworkManager.shared.addBusinessInterceptor(interceptor)
 
 // 4. 配置HTTPS证书（可选）
 SNNetworkManager.shared.configureSSL(with: .singleWay(serverTrust: nil))
 
 // 5. 发起请求
 struct User: Codable {
 let id: Int
 let name: String
 }
 
 // 普通请求
 let task = SNNetworkManager.shared.request<User>(
 "/user/profile",
 method: .get,
 success: { user in
 print("用户信息: \(user)")
 },
 failure: { error in
 print("请求失败: \(error)")
 }
 )
 
 // JSON字符串请求
 SNNetworkManager.shared.requestJSON(
 "/user/profile",
 method: .get,
 success: { jsonString in
 print("JSON响应: \(jsonString)")
 },
 failure: { error in
 print("请求失败: \(error)")
 }
 )
 
 // 上传文件
 if let imageData = UIImage(named: "avatar")?.jpegData(compressionQuality: 0.8) {
 SNNetworkManager.shared.upload<User>(
 "/user/avatar",
 data: imageData,
 method: .post,
 progressHandler: { progress in
 print("上传进度: \(progress)")
 },
 success: { user in
 print("上传成功: \(user)")
 },
 failure: { error in
 print("上传失败: \(error)")
 }
 )
 }
 
 // 多部分上传
 if let imageData = UIImage(named: "avatar")?.jpegData(compressionQuality: 0.8) {
 let uploadFile = SNUploadData(
 data: imageData,
 name: "avatar",
 fileName: "avatar.jpg",
 mimeType: "image/jpeg"
 )
 
 SNNetworkManager.shared.uploadMultipart<User>(
 "/user/upload",
 files: [uploadFile],
 parameters: ["userId": "123"],
 progressHandler: { progress in
 print("上传进度: \(progress)")
 },
 success: { user in
 print("上传成功: \(user)")
 },
 failure: { error in
 print("上传失败: \(error)")
 }
 )
 }
 
 // 下载文件
 let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
 let destinationURL = documentsPath.appendingPathComponent("document.pdf")
 
 SNNetworkManager.shared.download(
 "/files/document.pdf",
 destinationURL: destinationURL,
 progressHandler: { progress in
 print("下载进度: \(progress)")
 },
 success: { url in
 print("下载完成: \(url)")
 },
 failure: { error in
 print("下载失败: \(error)")
 }
 )
 
 // 取消请求
 // task.cancel()
 */
