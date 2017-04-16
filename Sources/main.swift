
let jsonString = "{\n\t\"name\": \"NIX\",\n\t\"age\": 18,\n\t\"detail\": {\n\t\t\"skills\": [\n\t\t\t\"Swift on iOS\",\n\t\t\t\"C on Linux\"\n\t\t],\n\t\t\"side_projects\": [\n\t\t\t{\n\t\t\t\t\"name\": \"coolie\",\n\t\t\t\t\"intro\": \"Generate models from a JSON file\",\n\t\t\t\t\"link\": \"https://github.com/nixzhu/Coolie\"\n\t\t\t},\n\t\t\t{\n\t\t\t\t\"name\": \"baby\",\n\t\t\t\t\"intro\": null\n\t\t\t}\n\t\t]\n\t},\n\t\"web_sites\": [\n\t\t\"https://twitter.com/nixzhu\"\n\t]\n}"
print(jsonString)
if let (value, remainder) = parse(jsonString) {
    let upgradedValue = value.upgraded(newName: "Model")
    print(upgradedValue)
    print(upgradedValue.structCode())
}
