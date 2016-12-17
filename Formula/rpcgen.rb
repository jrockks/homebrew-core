class Rpcgen < Formula
  desc "Protocol Compiler"
  homepage "https://opensource.apple.com/"
  url "https://opensource.apple.com/tarballs/developer_cmds/developer_cmds-62.tar.gz"
  sha256 "b11161df7a8dd293efe52213d8e968279dbff545a583e4706c4250d6cc122ce5"

  bottle do
    cellar :any_skip_relocation
    sha256 "75c923737996ecc27e2afe8e26e7b9bac572cbf03d543ef45c87a0e32e2da80b" => :sierra
    sha256 "17a73b22f1e7a7256bc232c113e4c4fd603f95b783d732478671c4a0a2958e62" => :el_capitan
  end

  keg_only :provided_by_macos

  depends_on :xcode => ["7.3", :build]

  # Add support for parsing 'hyper' and 'quad' types, as per RFC4506.
  # https://github.com/openbsd/src/commit/26f19e833517620fd866d2ef3b1ea76ece6924c5
  # https://github.com/freebsd/freebsd/commit/15a1e09c3d41cb01afc70a2ea4d20c5a0d09348a
  # Reported to Apple 13 Dec 2016 rdar://29644450
  patch :DATA

  def install
    xcodebuild "-project", "developer_cmds.xcodeproj",
               "-target", "rpcgen",
               "-configuration", "Release",
               "SYMROOT=build"
    bin.install "build/Release/rpcgen"
    man1.install "rpcgen/rpcgen.1"
  end

  test do
    assert_match "nettype", shell_output("#{bin}/rpcgen 2>&1", 1)
  end
end

__END__
diff --git a/rpcgen/rpc_parse.c b/rpcgen/rpc_parse.c
index 52edc9f..db0c1f1 100644
--- a/rpcgen/rpc_parse.c
+++ b/rpcgen/rpc_parse.c
@@ -580,6 +580,10 @@ get_type(prefixp, typep, dkind)
		*typep = "long";
		(void) peekscan(TOK_INT, &tok);
		break;
+	case TOK_HYPER:
+		*typep = "int64_t";
+		(void) peekscan(TOK_INT, &tok);
+		break;
	case TOK_VOID:
		if (dkind != DEF_UNION && dkind != DEF_PROGRAM) {
			error("voids allowed only inside union and program definitions with one argument");
@@ -592,6 +596,7 @@ get_type(prefixp, typep, dkind)
	case TOK_INT:
	case TOK_FLOAT:
	case TOK_DOUBLE:
+	case TOK_QUAD:
	case TOK_BOOL:
		*typep = tok.str;
		break;
@@ -622,6 +627,11 @@ unsigned_dec(typep)
		*typep = "u_long";
		(void) peekscan(TOK_INT, &tok);
		break;
+	case TOK_HYPER:
+		get_token(&tok);
+		*typep = "u_int64_t";
+		(void) peekscan(TOK_INT, &tok);
+		break;
	case TOK_INT:
		get_token(&tok);
		*typep = "u_int";
diff --git a/rpcgen/rpc_scan.c b/rpcgen/rpc_scan.c
index a8df441..4130107 100644
--- a/rpcgen/rpc_scan.c
+++ b/rpcgen/rpc_scan.c
@@ -419,8 +419,10 @@ static token symbols[] = {
	{TOK_UNSIGNED, "unsigned"},
	{TOK_SHORT, "short"},
	{TOK_LONG, "long"},
+	{TOK_HYPER, "hyper"},
	{TOK_FLOAT, "float"},
	{TOK_DOUBLE, "double"},
+	{TOK_QUAD, "quadruple"},
	{TOK_STRING, "string"},
	{TOK_PROGRAM, "program"},
	{TOK_VERSION, "version"},
diff --git a/rpcgen/rpc_scan.h b/rpcgen/rpc_scan.h
index bac2be4..e4c57c8 100644
--- a/rpcgen/rpc_scan.h
+++ b/rpcgen/rpc_scan.h
@@ -66,9 +66,11 @@ enum tok_kind {
	TOK_INT,
	TOK_SHORT,
	TOK_LONG,
+	TOK_HYPER,
	TOK_UNSIGNED,
	TOK_FLOAT,
	TOK_DOUBLE,
+	TOK_QUAD,
	TOK_OPAQUE,
	TOK_CHAR,
	TOK_STRING,