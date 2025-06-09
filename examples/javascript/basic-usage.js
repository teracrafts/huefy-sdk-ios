/**
 * Basic usage example for Huefy JavaScript SDK
 * 
 * This example demonstrates how to send emails using the Huefy SDK
 * in a Node.js environment.
 */

import { HuefyClient, TemplateNotFoundError, RateLimitError } from '@huefy/sdk';

// Initialize the client
const huefy = new HuefyClient({
  apiKey: process.env.HUEFY_API_KEY || 'your-api-key-here',
  // baseUrl: 'http://localhost:8080/api/v1/sdk', // For local development
});

async function main() {
  try {
    console.log('🚀 Huefy SDK Basic Usage Example');
    console.log('================================\n');

    // Example 1: Send a welcome email with default SES provider
    console.log('📧 Sending welcome email...');
    const welcomeResult = await huefy.sendEmail('welcome-email', {
      name: 'John Doe',
      company: 'Acme Corporation',
      verificationUrl: 'https://app.example.com/verify/abc123'
    }, 'john@example.com');

    console.log('✅ Welcome email sent successfully!');
    console.log(`   Message ID: ${welcomeResult.messageId}`);
    console.log(`   Provider: ${welcomeResult.provider}`);
    console.log('');

    // Example 2: Send a newsletter with SendGrid provider
    console.log('📰 Sending newsletter with SendGrid...');
    const newsletterResult = await huefy.sendEmail('newsletter', {
      name: 'Jane Smith',
      subject: 'Monthly Newsletter - January 2024',
      unsubscribeUrl: 'https://app.example.com/unsubscribe/xyz789'
    }, 'jane@example.com', {
      provider: 'sendgrid'
    });

    console.log('✅ Newsletter sent successfully!');
    console.log(`   Message ID: ${newsletterResult.messageId}`);
    console.log(`   Provider: ${newsletterResult.provider}`);
    console.log('');

    // Example 3: Send password reset email with Mailgun
    console.log('🔐 Sending password reset email with Mailgun...');
    const resetResult = await huefy.sendEmail('password-reset', {
      name: 'Bob Wilson',
      resetUrl: 'https://app.example.com/reset/token123',
      expiresAt: '2024-01-10 15:30:00 UTC'
    }, 'bob@example.com', {
      provider: 'mailgun'
    });

    console.log('✅ Password reset email sent successfully!');
    console.log(`   Message ID: ${resetResult.messageId}`);
    console.log(`   Provider: ${resetResult.provider}`);
    console.log('');

    // Example 4: Bulk email sending
    console.log('📮 Sending bulk emails...');
    const bulkResults = await huefy.sendBulkEmails([
      {
        templateKey: 'welcome-email',
        data: { name: 'Alice Johnson', company: 'Tech Corp' },
        recipient: 'alice@example.com'
      },
      {
        templateKey: 'welcome-email',
        data: { name: 'Charlie Brown', company: 'Design Studio' },
        recipient: 'charlie@example.com',
        options: { provider: 'mailchimp' }
      },
      {
        templateKey: 'newsletter',
        data: { name: 'Diana Prince', subject: 'Special Announcement' },
        recipient: 'diana@example.com',
        options: { provider: 'sendgrid' }
      }
    ]);

    console.log('✅ Bulk emails processed!');
    console.log(`   Total emails: ${bulkResults.length}`);
    
    const successCount = bulkResults.filter(r => r.success).length;
    const failureCount = bulkResults.filter(r => !r.success).length;
    
    console.log(`   Successful: ${successCount}`);
    console.log(`   Failed: ${failureCount}`);

    if (failureCount > 0) {
      console.log('\n❌ Failed emails:');
      bulkResults.filter(r => !r.success).forEach(result => {
        console.log(`   ${result.email}: ${result.error?.message}`);
      });
    }
    console.log('');

    // Example 5: Health check
    console.log('❤️ Checking API health...');
    const health = await huefy.healthCheck();
    console.log('✅ API is healthy!');
    console.log(`   Status: ${health.status}`);
    console.log(`   Version: ${health.version}`);
    console.log('');

    // Example 6: Template validation
    console.log('🔍 Validating template...');
    const isValid = await huefy.validateTemplate('welcome-email', {
      name: 'Test User',
      company: 'Test Company',
      verificationUrl: 'https://test.example.com/verify/test'
    });
    console.log(`✅ Template validation result: ${isValid ? 'Valid' : 'Invalid'}`);
    console.log('');

    console.log('🎉 All examples completed successfully!');

  } catch (error) {
    console.error('\n💥 Error occurred:');

    if (error instanceof TemplateNotFoundError) {
      console.error(`   Template not found: ${error.details.template_key}`);
      console.error('   Please check that the template exists in your Huefy dashboard.');
    } else if (error instanceof RateLimitError) {
      console.error('   Rate limit exceeded!');
      console.error(`   Try again after: ${error.details.reset_at}`);
    } else if (error.isHuefyError) {
      console.error(`   Huefy API Error: ${error.code}`);
      console.error(`   Message: ${error.message}`);
      if (error.details) {
        console.error(`   Details:`, error.details);
      }
    } else {
      console.error(`   Unexpected error: ${error.message}`);
    }

    process.exit(1);
  }
}

// Example with event callbacks for monitoring
async function exampleWithCallbacks() {
  console.log('\n🔔 Example with Event Callbacks');
  console.log('==============================\n');

  const huefyWithCallbacks = new HuefyClient({
    apiKey: process.env.HUEFY_API_KEY || 'your-api-key-here',
  }, {
    onSendStart: (request) => {
      console.log(`📤 Starting to send email with template: ${request.template_key}`);
    },
    onSendSuccess: (response) => {
      console.log(`✅ Email sent successfully: ${response.message_id}`);
    },
    onSendError: (error) => {
      console.log(`❌ Email send failed: ${error.message}`);
    },
    onRetry: (attempt, error) => {
      console.log(`🔄 Retry attempt ${attempt}: ${error.message}`);
    }
  });

  try {
    await huefyWithCallbacks.sendEmail('welcome-email', {
      name: 'Callback Example User',
      company: 'Example Corp'
    }, 'callback@example.com');
  } catch (error) {
    console.error('Callback example failed:', error.message);
  }
}

// Run examples
if (import.meta.url === `file://${process.argv[1]}`) {
  main()
    .then(() => exampleWithCallbacks())
    .then(() => {
      console.log('\n✨ All examples completed!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('Example failed:', error);
      process.exit(1);
    });
}