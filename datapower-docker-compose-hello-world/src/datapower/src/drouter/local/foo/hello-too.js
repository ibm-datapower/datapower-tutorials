var hm = require('header-metadata');

// Set the X-Hello-World header 
hm.current.set('X-Hello-World', 'Hello from DataPower domain foo');

session.input.readAsBuffer (function (error, buffer) {
    if (error) {
      // throw the error if there was one
      throw error;
    }
    // Since this simple application only returns a test hello world
    // string, we'll just prepend our placeholder string
    session.output.write("DataPower Proxied: " + buffer.toString());
});

