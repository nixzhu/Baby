
let jsonString = "{\"name\":\"NIX\",\"age\":18,\"detail\":{\"skills\":[\"Swift on iOS\",\"C on Linux\"],\"projects\":[{\"name\":\"coolie\",\"intro\":\"Generate models from a JSON file\"},{\"name\":\"parser\",\"intro\":null}]}}"
parse(jsonString)
    .flatMap({ print($0) })
