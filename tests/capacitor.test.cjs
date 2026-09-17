'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const raiz = join(__dirname, '..');
const ler = p => readFileSync(join(raiz, p), 'utf8');

test('config do Capacitor aponta para www e bundle provisório', ()=>{
  const c = JSON.parse(ler('capacitor.config.json'));
  assert.equal(c.appId, 'com.gstuchi.custta');
  assert.equal(c.appName, 'Custta');
  assert.equal(c.webDir, 'www');
  assert.equal(c.plugins.SplashScreen.launchAutoHide, false);
});

test('Info.plist: isento de criptografia, só retrato, push em segundo plano', ()=>{
  const plist = ler('ios/App/App/Info.plist');
  assert.match(plist, /<key>ITSAppUsesNonExemptEncryption<\/key>\s*<false\/>/);
  const orient = plist.match(/<key>UISupportedInterfaceOrientations<\/key>\s*<array>([\s\S]*?)<\/array>/)[1];
  assert.deepEqual([...orient.matchAll(/<string>([^<]+)<\/string>/g)].map(m=>m[1]), ['UIInterfaceOrientationPortrait']);
  assert.ok(!plist.includes('UISupportedInterfaceOrientations~ipad'));
  assert.match(plist, /<key>UIBackgroundModes<\/key>\s*<array>\s*<string>remote-notification<\/string>/);
});

test('projeto Xcode só para iPhone', ()=>{
  const pbx = ler('ios/App/App.xcodeproj/project.pbxproj');
  assert.ok(pbx.includes('TARGETED_DEVICE_FAMILY = 1;'));
  assert.ok(!pbx.includes('TARGETED_DEVICE_FAMILY = "1,2";'));
});
