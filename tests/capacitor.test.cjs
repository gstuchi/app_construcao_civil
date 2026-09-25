'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const raiz = join(__dirname, '..');
const ler = p => readFileSync(join(raiz, p), 'utf8');

test('config do Capacitor aponta para www e bundle definitivo', ()=>{
  const c = JSON.parse(ler('capacitor.config.json'));
  // Registrado na Apple e no Firebase; trocar quebra assinatura e push.
  assert.equal(c.appId, 'br.com.custta.app');
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
  const bundles = [...pbx.matchAll(/PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);/g)].map(m=>m[1]);
  assert.deepEqual(bundles, ['br.com.custta.app', 'br.com.custta.app'], 'bundle do Xcode diferente do capacitor.config.json');
  assert.ok(pbx.includes('TARGETED_DEVICE_FAMILY = 1;'));
  assert.ok(!pbx.includes('TARGETED_DEVICE_FAMILY = "1,2";'));
});
