<p align="center">
<img src="https://github.com/intsig171/SmartCodable/assets/87351449/89de27ac-1760-42ee-a680-4811a043c8b1" alt="SmartCodable" title="SmartCodable" width="500"/>
</p>

<h1 align="center">SmartCodable - Swift data decoding & encoding</h1>



[![Swift Package Manager](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager/)
[![Platforms](https://img.shields.io/cocoapods/p/ExCodable.svg)](#readme)
[![Build and Test](https://github.com/iwill/ExCodable/actions/workflows/build-and-test.yml/badge.svg)]()
[![LICENSE](https://img.shields.io/github/license/iwill/ExCodable.svg)](https://github.com/intsig171/SmartCodable/blob/main/LICENSE)

**SmartCodable** is a data parsing library based on Swift's **Codable** protocol, designed to provide more powerful and flexible parsing capabilities. By optimizing and rewriting the standard features of **Codable**, **SmartCodable** effectively solves common problems in the traditional parsing process and improves the fault tolerance and flexibility of parsing.

**SmartCodable** 是一个基于Swift的**Codable**协议的数据解析库，旨在提供更为强大和灵活的解析能力。通过优化和重写**Codable**的标准功能，**SmartCodable** 有效地解决了传统解析过程中的常见问题，并提高了解析的容错性和灵活性。

```
struct Model: SmartCodable {
    var age: Int?
    var name: String = ""
}

let model = Model.deserialize(from: json)
```



SmartCodable在Codable基础上做了大幅度的优化，支持：

| 类型   | 特性             | 说明                                                         |
| ------ | ---------------- | ------------------------------------------------------------ |
| 兼容   | 强大的异常兼容   | 当遇到数据类型错误/值为null/缺少数据等情况触发的Codable异常，可以完美兼容。 |
| 兼容   | 支持类型自适应   | 如JSON中是一个Int，但对应Model是String字段，会自动完成转化。 |
| 兼容   | 支持属性初始值   | 当解析失败时，使用此值填充。                                 |
| 兼容   | 内json的模型化   | 当某个数据是json时，支持进行Model化解析。                    |
| 新特性 | 支持Any的解析    | Codable不支持Any，SmartCodable支持！                         |
| 新特性 | 自定义Key映射    | 当数据字段和Model属性名不一致时，可以方便的自定义映射关系。  |
| 新特性 | 自定义Value解析  | 支持自定义解析规则                                           |
| 新特性 | 提供多种全局策略 | 数据的蛇形命名转驼峰，首字母转小写，首字母转大写             |
| 新特性 | 解析完成的回调   | 你可以知道解析完成的时机，去做一些事情。                     |
| 新特性 | 支持解析更新     | 对一个解析完成的model进行增量更新。                          |

## Use SmartCodable

### Installation - cocopods 

Add the following line to your `Podfile`:

```
pod 'SmartCodable'
```

Then, run the following command:

```
$ pod install
```

### Installation - Swift Package Manager

- File > Swift Packages > Add Package Dependency
- Add `https://github.com/intsig171/SmartCodable.git`



### Usages

```
import SmartCodable

struct Model: SmartCodable {
    var string: String?
    var date: Date?
    var subModel: SubModel?
    
    @SmartAny
    var dict: [String: Any]?
    
    @IgnoredKey
    var ignoreKey: String?
    
    static func mappingForKey() -> [SmartKeyTransformer]? {
        [
            CodingKeys.date <--- "nowDate"
        ]
    }
    
    static func mappingForValue() -> [SmartValueTransformer]? {
        [
            CodingKeys.date <--- SmartDateTransformer(),
        ]
    }
    
    func didFinishMapping() {
        // do something
    }
}

```

If you don't know how to use it, check it out.

如果你不知道如何使用，请查看它。

 [👉 How to use SmartCodable?](https://github.com/intsig171/SmartCodable/blob/develop/Document/README/Usages.md)



### Supported types

只要遵循了Codable，就可以参与解析。

* Int/Int8/Int16/Int32/Int64

* UInt/UInt8/UInt16/UInt32/UInt64

* String

* Bool

* Float/CGFloat/Double

* Dictionary（如果包含Any，请使用@SmartAny修饰该字典）

* Array（如果包含Any，请使用@SmartAny修饰该数组）

* URL/Date/Data/UIColor/enum

* 其他遵循了Codable协议的类型。

  



## SmarCodable Test

 [👉 To learn more about how SmartCodable is tested, click here](https://github.com/intsig171/SmartCodable/blob/main/Document/README/HowToTest.md)



## **Sentinel** 哨兵模式

SmartCodable内部集成了**Smart Sentinel**，它可以监听整个解析过程。当解析结束之后，输出格式化的日志信息。

该信息仅作辅助信息，帮助发现并排查问题。并不代表本次解析失败。

```
================================  [Smart Sentinel]  ================================
Array<SomeModel> 👈🏻 👀
   ╆━ Index 0
      ┆┄ a: Expected to decode 'Int' but found ‘String’ instead.
      ┆┄ b: Expected to decode 'Int' but found ’Array‘ instead.
      ┆┄ c: No value associated with key.
      ╆━ sub: SubModel
         ┆┄ sub_a: No value associated with key.
         ┆┄ sub_b: No value associated with key.
         ┆┄ sub_c: No value associated with key.
      ╆━ sub2s: [SubTwoModel]
         ╆━ Index 0
            ┆┄ sub2_a: No value associated with key.
            ┆┄ sub2_b: No value associated with key.
            ┆┄ sub2_c: No value associated with key.
         ╆━ Index 1
            ┆┄ sub2_a: Expected to decode 'Int' but found ’Array‘ instead.
   ╆━ Index 1
      ┆┄ a: No value associated with key.
      ┆┄ b: Expected to decode 'Int' but found ‘String’ instead.
      ┆┄ c: Expected to decode 'Int' but found ’Array‘ instead.
      ╆━ sub: SubModel
         ┆┄ sub_a: Expected to decode 'Int' but found ‘String’ instead.
      ╆━ sub2s: [SubTwoModel]
         ╆━ Index 0
            ┆┄ sub2_a: Expected to decode 'Int' but found ‘String’ instead.
         ╆━ Index 1
            ┆┄ sub2_a: Expected to decode 'Int' but found 'null' instead.
====================================================================================
```



如果你要使用它，请开启它：

```
SmartSentinel.debugMode = .verbose

public enum Level: Int {
    /// 不记录日志
    case none
    /// 详细的日志
    case verbose
    /// 警告日志：仅仅包含类型不匹配的情况
    case alert
}
```

如果你想获取这个日志用来上传服务器：

```
SmartSentinel.onLogGenerated { logs in
}
```





## Codable vs HandyJSON 

If you are using HandyJSON and would like to replace it, follow this link.

如果你正在使用HandyJSON，并希望替换掉它，请关注该链接。

 [👉 SmartCodable - Compare With HandyJSON](https://github.com/intsig171/SmartCodable/blob/develop/Document/README/CompareWithHandyJSON.md)

| 序号 | 🎯 特性                        | 💬 特性说明 💬                                                 | SmartCodable | HandyJSON |
| ---- | ----------------------------- | ------------------------------------------------------------ | ------------ | --------- |
| 1    | **强大的兼容性**              | 完美兼容：**字段缺失** & **字段值为nul** & **字段类型错误**  | ✅            | ✅         |
| 2    | **类型自适应**                | 如JSON中是一个Int，但对应Model是String字段，会自动完成转化   | ✅            | ✅         |
| 3    | **解析Any**                   | 支持解析 **[Any], [String: Any]** 等类型                     | ✅            | ✅         |
| 4    | **解码回调**                  | 支持Model解码完成的回调，即：**didFinishingMapping**         | ✅            | ✅         |
| 5    | **属性初始化值填充**          | 当解析失败时，支持使用初始的Model属性的赋值。                | ✅            | ✅         |
| 6    | **字符串的Model化**           | 字符串是json字符串，支持进行Model化解析                      | ✅            | ✅         |
| 7    | **枚举的解析**                | 当枚举解析失败时，支持兼容。                                 | ✅            | ✅         |
| 8    | **属性的自定义解析** - 重命名 | 自定义解码key（对解码的Model属性重命名）                     | ✅            | ✅         |
| 9    | **属性的自定义解析** - 忽略   | 忽略某个Model属性的解码                                      | ✅            | ✅         |
| 10   | **支持designatedPath**        | 实现自定义解析路径                                           | ✅            | ✅         |
| 11   | **Model的继承**               | 在model的继承关系下，Codable的支持力度较弱，使用不便（可以支持） | ❌            | ✅         |
| 12   | **自定义解析路径**            | 指定从json的层级开始解析                                     | ✅            | ✅         |
| 13   | **超复杂的数据解码**          | 解码过程中，多数据做进一步的整合/处理。如： 数据的扁平化处理 | ✅            | ⚠️         |
| 14   | **解码性能**                  | 在解码性能上，SmartCodable 平均强 30%                        | ✅            | ⚠️         |
| 15   | **异常解码日志**              | 当解码异常进行了兼容处理时，提供排查日志                     | ✅            | ❌         |
| 16   | **安全性方面**                | 底层实现的稳定性和安全性。                                   | ✅            | ❌         |



## Matters need attention（注意事项）

### 1.  parse very large data(大数据量解析)

When you parse very large data, try to avoid the compatibility of parsing exceptions, such as: more than one attribute is declared in the attribute, and the declared attribute type does not match. 

Do not use @IgnoredKey when there are attributes that do not need to be parsed, override CodingKeys to ignore unwanted attribute parsing. 

This can greatly improve the analytical efficiency.

当你解析超大大数据时候，尽量避免解析异常的兼容，比如：属性中多声明了一属性，声明的属性类型不匹配。

当有不需要参与解析属性，不要使用@IgnoredKey修饰，请重写CodingKeys忽略不需要的属性解析。

这样可以大幅度的提升解析效率。







## FAQ

If you're looking forward to learning more about the Codable protocol and the design thinking behind SmartCodable, check it out.

如果你期望了解更多Codable协议以及SmartCodable的设计思考，请关注它。	

[👉 learn more](https://github.com/intsig171/SmartCodable/blob/develop/Document/README/LearnMore.md)



## Github Stars
![GitHub stars](https://starchart.cc/intsig171/SmartCodable.svg?theme=dark)

## Join us

**SmartCodable** is an open source project, and we welcome all developers interested in improving data parsing performance and robustness. Whether it's using feedback, feature suggestions, or code contributions, your participation will greatly advance the **SmartCodable** project.

**SmartCodable** 是一个开源项目，我们欢迎所有对提高数据解析性能和健壮性感兴趣的开发者加入。无论是使用反馈、功能建议还是代码贡献，你的参与都将极大地推动 **SmartCodable** 项目的发展。

![QQ](https://github.com/intsig171/SmartCodable/assets/87351449/5d3a98fe-17ba-402f-aefe-3e7472f35f82)
