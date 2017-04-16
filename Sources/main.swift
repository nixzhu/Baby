
let jsonString = "{\"name\":\"NIX\",\"age\":18,\"detail\":{\"skills\":[\"Swift on iOS\",\"C on Linux\"],\"side_projects\":[{\"name\":\"coolie\",\"intro\":\"Generate models from a JSON file\",\"link\":\"https://github.com/nixzhu/Coolie\"},{\"name\":\"baby\",\"intro\":null}]},\"web_sites\":[\"https://twitter.com/nixzhu\"]}"
if let (value, remainder) = parse(jsonString) {
    let upgradedValue = value.upgraded(newName: "Model")
    print(upgradedValue)
    print(upgradedValue.structCode())
}
