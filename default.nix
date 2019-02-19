{
  mkDerivation, stdenv
, aeson, base, binary, bytestring, cereal, linear, milena, mtl
}:

mkDerivation {
  pname = "kafka-device";
  version = "1.0.0.0";
  src = ./.;
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [
    aeson base binary bytestring cereal linear milena mtl
  ];
  executableHaskellDepends = [
  ];
  homepage = "https://bitbucket.org/functionally/kafka-device";
  description = "UI device events via a Kafka message broker";
  license = stdenv.lib.licenses.mit;
}
