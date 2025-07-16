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
    case multipart
    
    var alamofireEncoding: ParameterEncoding {
        switch self {
        case .json: return JSONEncoding.default
        case .url: return URLEncoding.default
        case .multipart: return URLEncoding.default
        }
    }
}

// MARK: - 业务拦截器配置
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
        switch self {
        case .none:
            return session
        case .singleWay(let serverTrust):
            let trustManager = ServerTrustManager(allHostsMustBeEvaluated: false,
                                                evaluators: [:])
            let configuration = URLSessionConfiguration.default
            return Session(configuration: configuration,
                          serverTrustManager: trustManager)
        case .doubleWay(let clientCertificate, let clientKey):
            // 双向认证配置
            let trustManager = ServerTrustManager(allHostsMustBeEvaluated: true,
                                                evaluators: [:])
            let configuration = URLSessionConfiguration.default
            return Session(configuration: configuration,
                          serverTrustManager: trustManager)
        }
    }
}

// MARK: - 上传/下载进度回调
public typealias SNProgressHandler = (Double) -> Void // 进度百分比 0.0-1.0
public typealias SNUploadProgressHandler = (Double) -> Void
public typealias SNDownloadProgressHandler = (Double) -> Void

// MARK: - 响应回调
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

// MARK: - 网络请求结果
public enum SNNetworkResult<T> {
    case success(T)
    case failure(Error)
    case businessIntercepted(Any)
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
        self.session = sslConfig.configure(for: session)
    }
    
    // MARK: - 设置Session
    private func setupSession() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = self.configuration.timeout
        configuration.timeoutIntervalForResource = self.configuration.timeout
        
        // 添加拦截器
        var interceptors: [RequestInterceptor] = []
        interceptors.append(SNNetworkLoggerInterceptor(enabled: self.configuration.enableLogging))
        
        self.session = Session(configuration: configuration,
                              interceptor: Interceptor(interceptors: interceptors))
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
        ).validate().responseData { [weak self] response in
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
        ).validate().responseString { [weak self] response in
            self?.handleJSONResponse(response: response, success: success, failure: failure)
        }
        
        return SNRequestTaskImpl(request: request)
    }
    
    // MARK: - 上传方法
    @discardableResult
    public func upload<T: Codable>(
        _ url: String,
        data: Data,
        method: SNHTTPMethod = .post,
        parameters: [String: Any]? = nil,
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
            data,
            to: finalURL,
            method: method.alamofireMethod,
            headers: HTTPHeaders(finalHeaders)
        ).uploadProgress { progress in
            progressHandler?(progress.fractionCompleted)
        }.validate().responseData { [weak self] response in
            self?.handleResponse(response: response, success: success, failure: failure)
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
        }.validate().responseData { [weak self] response in
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
        
        // 修复点：为闭包添加显式类型注解
       var destination: DownloadRequest.Destination?
        
        if let destinationURL {
            destination = {
                (temporaryURL: URL, response: URLResponse?) -> (destinationURL: URL, options: DownloadRequest.Options) in
                return (destinationURL, [.removePreviousFile, .createIntermediateDirectories])
            }
        }
        
        let request = session.download(
            finalURL,
            method: method.alamofireMethod,
            parameters: finalParameters,
            headers: HTTPHeaders(finalHeaders),
            to: destination
        ).downloadProgress { progress in
            progressHandler?(progress.fractionCompleted)
        }.validate().response { response in
            switch response.result {
            case .success(let url):
                if let url = url {
                    success(url)
                } else {
                    failure(SNNetworkError.invalidResponse)
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
        
        if let headers = headers {
            for (key, value) in headers {
                finalHeaders[key] = value
            }
        }
        
        return finalHeaders
    }
    
    private func buildParameters(_ parameters: [String: Any]?) -> [String: Any] {
        var finalParameters = configuration.defaultParameters
        
        if let parameters = parameters {
            for (key, value) in parameters {
                finalParameters[key] = value
            }
        }
        
        return finalParameters
    }
    
    private func handleResponse<T: Codable>(
        response: AFDataResponse<Data>,
        success: @escaping SNSuccessHandler<T>,
        failure: @escaping SNFailureHandler
    ) {
        switch response.result {
        case .success(let data):
            logResponse(data: data, error: nil)
            
            // 检查业务拦截器
            if checkBusinessInterceptors(data: data) {
                return
            }
            
            // 解析数据
            do {
                let result = try JSONDecoder().decode(T.self, from: data)
                success(result)
            } catch {
                failure(error)
            }
            
        case .failure(let error):
            logResponse(data: nil, error: error)
            failure(error)
        }
    }
    
    private func handleJSONResponse(
        response: AFDataResponse<String>,
        success: @escaping SNJSONResponseHandler,
        failure: @escaping SNFailureHandler
    ) {
        switch response.result {
        case .success(let jsonString):
            logResponse(data: jsonString.data(using: .utf8), error: nil)
            
            // 检查业务拦截器
            if let data = jsonString.data(using: .utf8),
               checkBusinessInterceptors(data: data) {
                return
            }
            
            success(jsonString)
            
        case .failure(let error):
            logResponse(data: nil, error: error)
            failure(error)
        }
    }
    
    private func checkBusinessInterceptors(data: Data) -> Bool {
        guard !configuration.businessInterceptors.isEmpty else { return false }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            
            for interceptor in configuration.businessInterceptors {
                if let businessCode = getValueFromKeyPath(json, keyPath: configuration.businessCodeKeyPath) {
                    let codeString = "\(businessCode)"
                    if codeString == interceptor.businessCode {
                        interceptor.interceptHandler(json)
                        return true
                    }
                }
            }
        } catch {
            // JSON解析失败，不进行拦截
        }
        
        return false
    }
    
    private func getValueFromKeyPath(_ object: Any, keyPath: String) -> Any? {
        let keys = keyPath.split(separator: ".").map(String.init)
        var current = object
        
        for key in keys {
            if let dict = current as? [String: Any] {
                guard let value = dict[key] else { return nil }
                current = value
            } else {
                return nil
            }
        }
        
        return current
    }
    
    private func logRequest(url: String, method: SNHTTPMethod, parameters: [String: Any]?, headers: [String: String]) {
        guard configuration.enableLogging else { return }
        
        print("🚀 SNNetworkManager Request:")
        print("URL: \(url)")
        print("Method: \(method)")
        if let parameters = parameters {
            print("Parameters: \(parameters)")
        }
        print("Headers: \(headers)")
        print("---")
    }
    
    private func logResponse(data: Data?, error: Error?) {
        guard configuration.enableLogging else { return }
        
        print("📦 SNNetworkManager Response:")
        if let data = data {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Response: \(jsonString)")
            }
        }
        if let error = error {
            print("Error: \(error)")
        }
        print("---")
    }
}

// MARK: - 网络错误枚举
public enum SNNetworkError: Error {
    case invalidResponse
    case noData
    case decodingError
    case businessCodeIntercepted(String)
    
    public var localizedDescription: String {
        switch self {
        case .invalidResponse:
            return "Invalid response"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .businessCodeIntercepted(let code):
            return "Business code intercepted: \(code)"
        }
    }
}

// MARK: - 日志拦截器
private class SNNetworkLoggerInterceptor: RequestInterceptor {
    private let enabled: Bool
    
    init(enabled: Bool) {
        self.enabled = enabled
    }
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        if enabled {
            print("🔄 Adapting request: \(urlRequest)")
        }
        completion(.success(urlRequest))
    }
    
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        if enabled {
            print("🔄 Retrying request due to error: \(error)")
        }
        completion(.doNotRetry)
    }
}

// MARK: - 扩展方法
extension SNNetworkManager {
    
    // MARK: - 添加业务拦截器
    public func addBusinessInterceptor(_ interceptor: SNBusinessInterceptor) {
        configuration.businessInterceptors.append(interceptor)
    }
    
    // MARK: - 移除业务拦截器
    public func removeBusinessInterceptor(for businessCode: String) {
        configuration.businessInterceptors.removeAll { $0.businessCode == businessCode }
    }
    
    // MARK: - 清空所有业务拦截器
    public func clearBusinessInterceptors() {
        configuration.businessInterceptors.removeAll()
    }
    
    // MARK: - 更新默认参数
    public func updateDefaultParameters(_ parameters: [String: Any]) {
        configuration.defaultParameters = parameters
    }
    
    // MARK: - 添加默认参数
    public func addDefaultParameter(key: String, value: Any) {
        configuration.defaultParameters[key] = value
    }
    
    // MARK: - 移除默认参数
    public func removeDefaultParameter(key: String) {
        configuration.defaultParameters.removeValue(forKey: key)
    }
    
    // MARK: - 更新默认头部
    public func updateDefaultHeaders(_ headers: [String: String]) {
        configuration.defaultHeaders = headers
    }
    
    // MARK: - 添加默认头部
    public func addDefaultHeader(key: String, value: String) {
        configuration.defaultHeaders[key] = value
    }
    
    // MARK: - 移除默认头部
    public func removeDefaultHeader(key: String) {
        configuration.defaultHeaders.removeValue(forKey: key)
    }
    
    // MARK: - 更新baseURL
    public func updateBaseURL(_ baseURL: String) {
        configuration.baseURL = baseURL
    }
    
    // MARK: - 启用/禁用日志
    public func setLoggingEnabled(_ enabled: Bool) {
        configuration.enableLogging = enabled
        setupSession()
    }
    
    // MARK: - 设置超时时间
    public func setTimeout(_ timeout: TimeInterval) {
        configuration.timeout = timeout
        setupSession()
    }
    
    // MARK: - 取消所有请求
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
