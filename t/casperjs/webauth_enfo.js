var utils = require('utils');
var system = require('system');

var base_url = casper.cli.get('base_url');

var mgmt_int = casper.cli.get('mgmt_int');

var number_of_tests = 12;

// Initiate test

casper.test.begin('Packetfence Configurator Enforcement Test', number_of_tests, function suite(test) {
    casper.start(base_url + "/configurator/" , function() {
        test.assertTitle("Configurator - PacketFence");
        test.assertExists('form[name="enforcement"]', "enforcement form is found");
        test.assertExists('#enforcement_webauth', "enforcement_webauth field found");
        test.assertExists('button[type="submit"]', "submit button found");
        this.evaluate(function() {
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
        test.assertExists('a[href="http://127.0.0.1:3000/interface/' + mgmt_int + '/read"]', "interface link is found");
        this.click('a[href="http://127.0.0.1:3000/interface/' + mgmt_int + '/read"]');
        casper.wait(3000, function() {
            this.echo("waited 3sec to load the module");
        });
    });
    
    // Change the interface settings
    
    casper.then(function() {
        test.assertExists('div[class=modal-body]', "Modal body is present");
        this.fill('form[name="modalEditInterface"]', {
            'ipaddress' :   '172.20.20.66',
            'netmask' :     '255.255.0.0',
        });

        this.evaluate(function() {
            document.getElementById("#type").selectedIndex = 1; //.value('portal');
            document.getElementById("#additional_listening_daemons").selectedIndex = 0; //.value('portal');
            document.querySelector('button[type="submit"]').click();
            document.getElementById('#save_int').click();
        });
        //this.click('#save_int');
        casper.wait(2000, function() {
            this.echo("waited 2sec to close the form");
        });
        test.assertExists('form[name="networks"]', "networks form is found");
        this.fill('form[name="networks"]', {
            'gateway' :     '172.20.0.1',
        });

        this.evaluate(function() {
            document.querySelector('button[type="submit"]').click();
        });
    });
    
    // Configure the database

    casper.waitForSelector("i.icon-user.icon-white", function() {}, function() {}, 500);

    casper.then(function() {
        test.assertTitle("Configurator - PacketFence");
        test.assertUrlMatch(/configurator\/database/, "We are on the database page");
        test.assertExists('form[name="database"]', "database form is found");
        /*this.capture('test.png', {
            top: 0,
            left: 0,
            width: 1000,
            height: 1200
        });*/

        this.fill('form[name="database"]', {
            'root_password':    'inverse',
        }); 
        this.click('#testDatabase');
        this.click('#createDatabase');
        this.fill('form[name="database"]', {
            'database.pass':    'pf',
            'database.pass2':    'pf',
        });
        this.click('#assignUser');
        this.evaluate(function() {
            document.querySelector('button[type="submit"]').click();
        });
    });

    // Configure PacketFence

    casper.waitForSelector("i.icon-user.icon-white", function() {}, function() {}, 500);

    /*casper.then(function() {
        test.assertTitle("Configurator - PacketFence");
        test.assertUrlMatch(/configurator\/configuration/, "We are on the configuration page");
        test.assertExists('form[name="config"]', "config form is found");
        this.fill('form[name="config"]', {
            'general_domain':       'local',
            'general_hostname':     'pf',
            'alerting_emailaddr':   'support@inverse.ca',
        }); 
        this.evaluate(function() {
            document.querySelector('button[type="submit"]').click();
        });
    });

    // Configure the admin password
    
    casper.waitForSelector("i.icon-user.icon-white", function() {}, function() {}, 500);

    casper.then(function() {
        test.assertTitle("Configurator - PacketFence");
        test.assertUrlMatch(/configurator\/admin/, "We are on the admin password page");
        test.assertExists('form[name="admin"]', "admin form is found");
        this.fill('form[name="admin"]', {
            'admin_password':   'inverse',
            'admin_password2':  'inverse',
        }); 
        this.click('#adminPassword');
        this.evaluate(function() {
            document.querySelector('button[type="submit"]').click();
        });
    });*/

    casper.run(function() {
        test.done();
    });
});

