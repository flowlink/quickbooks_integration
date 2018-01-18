# Quickbooks Online Integration

## Overview

[Quickbooks](http://quickbooks.intuit.com) is an accounting software package developed and marketed by [Intuit](http://www.intuit.com). This implementation uses the [Quickbooks v3 API](https://developer.intuit.com/apiexplorer?apiname=V3QBO) through the [quickbooks-ruby](https://github.com/ruckus/quickbooks-ruby) gem.

Please visit the [wiki](https://github.com/flowlink/quickbooks_integration/wiki)
for further info on how to connect this integration.

This is a fully hosted and supported integration for use with the [FlowLink](http://flowlink.io/)
product. With this integration you can perform the following functions:

* Send orders to Quickbooks as Sales Receipts
* Send products to Quickbooks as Items
* Send returns to Quickbooks as Credit Memo
* Poll for inventory stock levels in Quickbooks

### 21 Character limit on Order numbers.

If your having problems with it, this transform should help:
```javascript
//nomustache
payload.order.number = payload.order.number.substring(0, 21);
```

## Development

### Generate OAuth Keys

Create an app here: https://developer.intuit.com/v2/ui#/app/dashboard and generate your oauth keys.

### Environment Variables

Copy "sample.env" to ".env" and fill out the following variables:

`QB_CONSUMER_KEY` - OAuth consumer key

`QB_CONSUMER_SECRET` - OAuth token

# Starting Application

`bundle exec unicorn` -- Starts application on port 8080

```sh
$ docker rm -f quickbooks-integration-container
$ docker build -t quickbooks-integration .
$ docker run -t -e VIRTUAL_HOST=quickbooks_integration.flowlink.io -e RAILS_ENV=development -v $PWD:/app -p 3001:5000 -e QB_CONSUMER_KEY=qyprd5ViUa4HUra00S2Y5Zv098f9Ah -e QB_CONSUMER_SECRET=fc44axqkmC9bf8yzeRvFBFJkCqilyIuW132rPkdz --name quickbooks-integration-container quickbooks-integration
```

# About FlowLink

[FlowLink](http://flowlink.io/) allows you to connect to your own custom integrations.
Feel free to modify the source code and host your own version of the integration
or better yet, help to make the official integration better by submitting a pull request!

This integration is 100% open source an licensed under the terms of the New BSD License.

![FlowLink Logo](http://flowlink.io/wp-content/uploads/logo-1.png)
