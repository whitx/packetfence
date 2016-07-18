var utils = require('utils');
var system = require('system');

var base_url = casper.cli.get('base_url');

var number_of_tests = 8;

casper.test.begin('Packetfence Configurator Enforcement Test', number_of_tests, function suite(test) {
    casper.start(base_url + "/configurator/" , function() {
        test.assertTitle("Configurator - PacketFence");
        test.assertExists('form[name="enforcement"]', "enforcement form is found");
        test.assertExists('#enforcement_webauth', "enforcement_webauth field found");
        test.assertExists('button[type="submit"]', "submit button found");
        this.evaluate(function(enforcement_webauth) {
            document.querySelector('#enforcement_webauth').click();
            document.querySelector('button[type="submit"]').click();
        });
    });

    // Just wait for a half second for the page to be loaded from the form submit

    casper.waitForSelector("i.icon-user.icon-white", function() {}, function() {}, 500);

    casper.then(function() {
        test.assertTitle("Configurator - PacketFence");
        test.assertUrlMatch(/configurator\/networks/, "We are on the networks page");
        test.assertExists('form[name=interfaces]', "interfaces form is found");
        test.assertExists('a[href="http://127.0.0.1:3000/interface/ens192/read"]', "interface_192 link is found");
        this.evaluate(function() {
            document.querySelector('a[href="http://127.0.0.1:3000/interface/ens192/read"]').click();
        });
    });
    
    casper.wait(2000, function() {
        this.echo("waited 2 sec");
        this.echo(this.getHTML());
    });
    
    // Change the interface settings
    
    casper.then(function() {
//        test.assertExists('form[action="http://127.0.0.1:3000/interface/ens192/update"]', "widget is present");
//        test.assertExists('div[class=modal-header]', "Modal header is present");
    });

    casper.run(function() {
        test.done();
    });
});

