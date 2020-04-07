package test

import (
	"fmt"
	"net"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

func TestTerraformSESDomain(t *testing.T) {
	t.Parallel()

	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/simple")
	testName := fmt.Sprintf("ses-domain-%s", strings.ToLower(random.UniqueId()))
	testDomain := fmt.Sprintf("%s.infra-test.truss.coffee", testName)
	sesBucketName := fmt.Sprintf("%s-ses", testName)
	awsRegion := "us-west-2"

	terraformOptions := &terraform.Options{
		TerraformDir: tempTestFolder,
		Vars: map[string]interface{}{
			"region":     awsRegion,
			"test_name":  testName,
			"ses_bucket": sesBucketName,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	defer aws.EmptyS3Bucket(t, awsRegion, sesBucketName)

	terraform.InitAndApply(t, terraformOptions)

	logger.Log(t, testDomain)

	txtrecords, _ := net.LookupTXT(testDomain)
	logger.Log(t, txtrecords)

	for _, txt := range txtrecords {
		logger.Log(t, txt)
	}
}
