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

/* Bloco XCBuildConfiguration do target App (o que tem INFOPLIST_FILE) com o nome dado. */
function configAlvo(pbx, nome){
  const blocos = [...pbx.matchAll(/isa = XCBuildConfiguration;[\s\S]*?name = (\w+);/g)]
    .filter(m => m[1] === nome && m[0].includes('INFOPLIST_FILE'));
  assert.equal(blocos.length, 1, `config ${nome} do target App não encontrada`);
  return blocos[0][0];
}

test('Firebase iOS: plist do bundle certo e empacotado no app', ()=>{
  const plist = ler('ios/App/App/GoogleService-Info.plist');
  assert.match(plist, /<key>BUNDLE_ID<\/key>\s*<string>br\.com\.custta\.app<\/string>/);
  assert.match(plist, /<key>PROJECT_ID<\/key>\s*<string>app-construcao-civil<\/string>/);
  const pbx = ler('ios/App/App.xcodeproj/project.pbxproj');
  const recursos = pbx.match(/isa = PBXResourcesBuildPhase;[\s\S]*?files = \(([\s\S]*?)\);/)[1];
  assert.match(recursos, /GoogleService-Info\.plist in Resources/, 'sem o plist no bundle o FCM não inicializa');
});

test('push: aps-environment vem da configuração e bate com o perfil', ()=>{
  const ent = ler('ios/App/App/App.entitlements');
  assert.match(ent, /<key>aps-environment<\/key>\s*<string>\$\(APS_ENVIRONMENT\)<\/string>/);
  const pbx = ler('ios/App/App.xcodeproj/project.pbxproj');
  const debug = configAlvo(pbx, 'Debug'), release = configAlvo(pbx, 'Release');
  for(const c of [debug, release]){
    assert.match(c, /CODE_SIGN_ENTITLEMENTS = App\/App\.entitlements;/);
    assert.match(c, /DEVELOPMENT_TEAM = 4S7JKDKN27;/);
  }
  assert.match(debug, /APS_ENVIRONMENT = development;/);
  assert.match(debug, /CODE_SIGN_STYLE = Automatic;/);
  assert.match(release, /APS_ENVIRONMENT = production;/);
});

test('Release assina com o perfil App Store, sem depender de aparelho cadastrado', ()=>{
  const release = configAlvo(ler('ios/App/App.xcodeproj/project.pbxproj'), 'Release');
  assert.match(release, /CODE_SIGN_STYLE = Manual;/);
  assert.match(release, /PROVISIONING_PROFILE_SPECIFIER = "Custta App Store";/);
  assert.match(release, /"CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]" = "Apple Distribution";/);
});

test('AppDelegate repassa token e notificação ao plugin do Firebase', ()=>{
  const app = ler('ios/App/App/AppDelegate.swift');
  assert.match(app, /capacitorDidRegisterForRemoteNotifications/);
  assert.match(app, /didReceiveRemoteNotification userInfo/);
  assert.match(app, /Notification\.Name\("didReceiveRemoteNotification"\)/);
});

test('Info.plist exige arm64, não armv7', ()=>{
  const plist = ler('ios/App/App/Info.plist');
  const caps = plist.match(/<key>UIRequiredDeviceCapabilities<\/key>\s*<array>([\s\S]*?)<\/array>/)[1];
  assert.deepEqual([...caps.matchAll(/<string>([^<]+)<\/string>/g)].map(m=>m[1]), ['arm64']);
});

test('manifesto de privacidade empacotado e igual aos labels da loja', ()=>{
  const pbx = ler('ios/App/App.xcodeproj/project.pbxproj');
  const recursos = pbx.match(/isa = PBXResourcesBuildPhase;[\s\S]*?files = \(([\s\S]*?)\);/)[1];
  assert.ok(recursos.includes('PrivacyInfo.xcprivacy in Resources'), 'manifesto fora da fase Copy Bundle Resources');

  const xml = ler('ios/App/App/PrivacyInfo.xcprivacy');
  assert.match(xml, /<key>NSPrivacyTracking<\/key>\s*<false\/>/);
  // Tipo → [vinculado, finalidade], na ordem da tabela de docs/app-store-metadados.md.
  const tipos = [...xml.matchAll(/<string>NSPrivacyCollectedDataType(\w+)<\/string>\s*<key>NSPrivacyCollectedDataTypeLinked<\/key>\s*<(true|false)\/>\s*<key>NSPrivacyCollectedDataTypeTracking<\/key>\s*<false\/>\s*<key>NSPrivacyCollectedDataTypePurposes<\/key>\s*<array>\s*<string>NSPrivacyCollectedDataTypePurpose(\w+)<\/string>\s*<\/array>/g)]
    .map(m => [m[1], m[2] === 'true', m[3]]);
  assert.deepEqual(tipos, [
    ['EmailAddress', true, 'AppFunctionality'],
    ['Name', true, 'AppFunctionality'],
    ['OtherUserContent', true, 'AppFunctionality'],
    ['DeviceID', true, 'AppFunctionality'],
    ['CrashData', false, 'AppFunctionality'],
    ['OtherDataTypes', true, 'Analytics'],
  ]);
  const labels = ler('docs/app-store-metadados.md').split('## App Privacy labels')[1].split('\n## ')[0];
  assert.equal(labels.match(/^\| [^-|][^|]* \| Sim \|/gm).length, tipos.length, 'tabela de labels e manifesto com quantidades diferentes');

  // IONFilesystemLib (via @capacitor/filesystem) lê data de arquivo e não traz manifesto próprio.
  assert.match(xml, /NSPrivacyAccessedAPICategoryFileTimestamp<\/string>\s*<key>NSPrivacyAccessedAPITypeReasons<\/key>\s*<array>\s*<string>C617\.1<\/string>/);
});

test('Sign in with Apple: entitlement e plugin nativo no pacote SPM', ()=>{
  const ent = ler('ios/App/App/App.entitlements');
  assert.match(ent, /<key>com\.apple\.developer\.applesignin<\/key>\s*<array>\s*<string>Default<\/string>\s*<\/array>/);
  assert.match(ent, /<key>aps-environment<\/key>/, 'push continua');
  const pkg = JSON.parse(ler('package.json'));
  assert.ok(pkg.devDependencies['@capawesome/capacitor-apple-sign-in'], 'plugin no package.json');
  const spm = ler('ios/App/CapApp-SPM/Package.swift');
  assert.match(spm, /\.package\(name: "CapawesomeCapacitorAppleSignIn", path: "\.\.\/\.\.\/\.\.\/node_modules\/@capawesome\/capacitor-apple-sign-in"\)/);
  assert.match(spm, /\.product\(name: "CapawesomeCapacitorAppleSignIn", package: "CapawesomeCapacitorAppleSignIn"\)/);
});

test('Google Sign-In: plugin no SPM e Info.plist com o client iOS do GoogleService-Info.plist', ()=>{
  const pkg = JSON.parse(ler('package.json'));
  assert.ok(pkg.devDependencies['@capawesome/capacitor-google-sign-in'], 'plugin no package.json');
  const spm = ler('ios/App/CapApp-SPM/Package.swift');
  assert.match(spm, /\.package\(name: "CapawesomeCapacitorGoogleSignIn", path: "\.\.\/\.\.\/\.\.\/node_modules\/@capawesome\/capacitor-google-sign-in"\)/);
  assert.match(spm, /\.product\(name: "CapawesomeCapacitorGoogleSignIn", package: "CapawesomeCapacitorGoogleSignIn"\)/);
  const google = ler('ios/App/App/GoogleService-Info.plist');
  const valor = chave => google.match(new RegExp(`<key>${chave}</key>\\s*<string>([^<]+)</string>`))[1];
  const plist = ler('ios/App/App/Info.plist');
  assert.equal(plist.match(/<key>GIDClientID<\/key>\s*<string>([^<]+)<\/string>/)?.[1], valor('CLIENT_ID'));
  // Sem o esquema de URL o SDK do Google lança exceção ao abrir o login e o app fecha.
  const esquemas = plist.match(/<key>CFBundleURLSchemes<\/key>\s*<array>([\s\S]*?)<\/array>/)?.[1] || '';
  assert.ok(esquemas.includes(`<string>${valor('REVERSED_CLIENT_ID')}</string>`), 'esquema REVERSED_CLIENT_ID no Info.plist');
});
