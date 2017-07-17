# Baby

Create models from a JSON file, even a Baby can do it.

## Description

Baby can detect property's type from json such as `String`, `Int`, `Double`, `URL` and `Date`.

Baby can handle nested json, it will generate nested models.

Baby supports `Codable` from Swift 4.

### Example

JSON:

``` json
{
    "id": 42,
    "name": "nixzhu",
    "twitter": {
        "profile_url": "https://twitter.com/nixzhu",
        "created_at": "2009-05-12T10:25:43.511Z"
    }
}
```

Swift code with `Codable`:

``` swift
struct User: Codable {
    let id: Int
    let name: String
    struct Twitter: Codable {
        let profileURL: URL
        let createdAt: Date
        private enum CodingKeys: String, CodingKey {
            case profileURL = "profile_url"
            case createdAt = "created_at"
        }
    }
    let twitter: Twitter
}
```

Note that I use **Property Map** `profile_url: profileURL` to change the property name (Automatically generated will be `profileUrl`).

Baby can also handle array root json, it will automatically merge properties for objects in array.

## Installation

### Build

```bash
$ bash install.sh
```

### Run

``` bash
$ baby -i JSONFilePath
```

## Help

``` bash
$ baby --help
```

Or, try Baby's web interface [SharedBaby](https://github.com/nixzhu/SharedBaby).

## Contact

You can find me on [Twitter](https://twitter.com/nixzhu) or [Weibo](https://weibo.com/nixzhu).

## License

MIT
