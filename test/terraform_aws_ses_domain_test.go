package test

import (
	"fmt"
	"net"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

func TestTerraformSESDomainWithSPFEnabled(t *testing.T) {
	t.Parallel()

	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/simple")
	testName := fmt.Sprintf("ses-domain-%s", strings.ToLower(random.UniqueId()))
	testDomain := fmt.Sprintf("%s.infra-test.truss.coffee", testName)
	sesBucketName := fmt.Sprintf("%s-ses", testName)
	awsRegion := "us-west-2"

	terraformOptions := &terraform.Options{
		TerraformDir: tempTestFolder,
		Vars: map[string]interface{}{
			"test_name":         testName,
			"ses_bucket":        sesBucketName,
			"enable_spf_record": true,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	txtrecords, _ := net.LookupTXT(testDomain)

	assert.NotContains(t, txtrecords, "v=spf1 include:_spf.google.com include:servers.mcsv.net ~all")
	assert.Contains(t, txtrecords, "v=spf1 include:amazonses.com -all")
}

func TestTerraformSESDomainWithSPFDisabled(t *testing.T) {
	t.Parallel()

	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/simple")
	testName := fmt.Sprintf("ses-domain-%s", strings.ToLower(random.UniqueId()))
	testDomain := fmt.Sprintf("%s.infra-test.truss.coffee", testName)
	sesBucketName := fmt.Sprintf("%s-ses", testName)
	awsRegion := "us-west-2"

	terraformOptions := &terraform.Options{
		TerraformDir: tempTestFolder,
		Vars: map[string]interface{}{
			"test_name":         testName,
			"ses_bucket":        sesBucketName,
			"enable_spf_record": false,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	txtrecords, _ := net.LookupTXT(testDomain)

	assert.Contains(t, txtrecords, "v=spf1 include:_spf.google.com include:servers.mcsv.net ~all")
	assert.NotContains(t, txtrecords, "v=spf1 include:amazonses.com -all")
}

func TestTerraformSESDomainWithExtraSESRecords(t *testing.T) {
	t.Parallel()

	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/simple")
	testName := fmt.Sprintf("ses-domain-%s", strings.ToLower(random.UniqueId()))
	testDomain := fmt.Sprintf("_amazonses.%s.infra-test.truss.coffee", testName)
	sesBucketName := fmt.Sprintf("%s-ses", testName)
	awsRegion := "us-west-2"
	extraRecords := []string{"stringThing1.infra-test.truss.coffee", "stringThing2.infra-test.truss.coffee"}

	terraformOptions := &terraform.Options{
		TerraformDir: tempTestFolder,
		Vars: map[string]interface{}{
			"test_name":         testName,
			"ses_bucket":        sesBucketName,
			"enable_spf_record": true,
			"extra_ses_records": extraRecords,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	txtrecords, _ := net.LookupTXT(testDomain)

	assert.Contains(t, txtrecords, "stringThing1.infra-test.truss.coffee")
}
