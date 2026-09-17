import localUnitTest from './LocalUnit.test';
import base64UtilTest from './Base64Util.test';
import tokenPayloadTest from './TokenPayload.test';
import migrationRegistryTest from './MigrationRegistry.test';
import tokenSchemaTest from './TokenSchema.test';
import secretNormalizerTest from './SecretNormalizer.test';

export default function testsuite() {
  localUnitTest();
  base64UtilTest();
  tokenPayloadTest();
  migrationRegistryTest();
  tokenSchemaTest();
  secretNormalizerTest();
}
