const { InstancesClient } = require('@google-cloud/compute');
const compute = new InstancesClient();

/**
 * Triggered from a message on a Cloud Pub/Sub topic.
 *
 * @param {object} message The Pub/Sub message.
 * @param {object} context The event metadata.
 */
exports.stopBilling = async (message, context) => {
  const pubsubData = message.data
    ? JSON.parse(Buffer.from(message.data, 'base64').toString())
    : null;

  if (!pubsubData) {
    console.log('No data received');
    return;
  }

  console.log(`Cost Amount: ${pubsubData.costAmount}, Budget Amount: ${pubsubData.budgetAmount}`);

  // Check if the budget limit (1.0 threshold) has been reached or exceeded
  if (pubsubData.alertThresholdExceeded && pubsubData.alertThresholdExceeded >= 1.0) {
    console.log('Budget limit exceeded. Attempting to stop services...');

    const projectId = process.env.PROJECT_ID;
    const zone = process.env.ZONE;
    const instanceName = process.env.INSTANCE_NAME;

    if (instanceName && zone && projectId) {
      try {
        console.log(`Stopping instance: ${instanceName} in zone ${zone}...`);
        
        const [response] = await compute.stop({
          project: projectId,
          zone: zone,
          instance: instanceName,
        });

        console.log(`Stop request sent. Operation status: ${response.status}`);
      } catch (err) {
        console.error('Error stopping instance:', err);
      }
    } else {
      console.log('Instance configuration missing. Skipping VM shutdown.');
    }
  } else {
    console.log('Budget not yet exceeded or no threshold triggered.');
  }
};