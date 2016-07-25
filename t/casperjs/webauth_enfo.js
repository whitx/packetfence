var utils = require('utils');
var system = require('system');

var base_url = casper.cli.get('base_url');

var number_of_tests = 9;

// Initiate test

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
        this.clickLabel('ens192');
        casper.wait(1000, function() {
            this.echo("waited 1sec to load the module");
        });
    });
    
    // Change the interface settings
    
    casper.then(function() {
        test.assertExists('div[class=modal-body]', "Modal body is present");
        this.fill('#modalEditInterface', {
            'ipaddress' :   '172.21.130.1',
            'netmask' :     '255.255.0.0',
        });
        this.capture('test.png', {
            top: 0,
            left: 0,
            width: 1000,
            height: 1000
        });
    });

    casper.run(function() {
        test.done();
    });
});

