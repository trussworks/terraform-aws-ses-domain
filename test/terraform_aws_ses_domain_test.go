package test

import (
	"fmt"
	"net"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
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
			"region":            awsRegion,
			"test_name":         testName,
			"ses_bucket":        sesBucketName,
			"enable_spf_record": true,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	defer aws.EmptyS3Bucket(t, awsRegion, sesBucketName)

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
			"region":            awsRegion,
			"test_name":         testName,
			"ses_bucket":        sesBucketName,
			"enable_spf_record": false,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	defer aws.EmptyS3Bucket(t, awsRegion, sesBucketName)

	terraform.InitAndApply(t, terraformOptions)

	txtrecords, _ := net.LookupTXT(testDomain)

	assert.Contains(t, txtrecords, "v=spf1 include:_spf.google.com include:servers.mcsv.net ~all")
	assert.NotContains(t, txtrecords, "v=spf1 include:amazonses.com -all")
}
