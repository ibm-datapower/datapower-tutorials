let sm = require ('service-metadata');

let method = sm.getVar ('var://service/protocol-method');
let uri = sm.getVar ('var://service/URI');

session.output.write({ method: method, uri: uri });
