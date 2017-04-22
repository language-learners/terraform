console.log('Loading');
const aws = require('aws-sdk');
const async = require('async');

// Export a handler to be called from ECS.
exports.handler = (event, context, callback) => {
  const ecsCluster = 'language-learners';
  const ecsService = 'phpbb';
  const ecsRegion = 'us-east-1';
  const imageTag = '7c05000a-a357-483d-a839-cedd3b0031a3';

  // Configure the AWS APIs that we'll need to use.
  const ecs = new aws.ECS({ region: ecsRegion });

  // Declare some variables we want to pass between stages of our
  // "waterfall," below.
  const images = [];

  // Use `async.waterfall` to run a chained series of callbacks, giving up
  // early if there's an error.
  async.waterfall([

    // Look up our ECS service.
    (callback) => {
      const query = {
        cluster: ecsCluster,
        services: [ecsService]
      };
      ecs.describeServices(query, callback);
    },

    // Look up the task definition associated with our ECS service.
    (data, callback) => {
      const service = data.services[0];
      //console.log("service:", service);
      ecs.describeTaskDefinition({ taskDefinition: service.taskDefinition }, callback);
    },

    // Register a new task definition using the newest version of our image.
    (data, callback) => {
      const taskDefinition = data.taskDefinition;
      //console.log("taskDefinition:", taskDefinition);

      // Figure out which containers need to be updated, and update them.
      for (const container of taskDefinition.containerDefinitions) {
        if (container.name === ecsService) {
          //console.log(container);
          const newImage = container.image.replace(/:([^:]*)$/, ":" + imageTag);
          console.log("Updating container to use new image:", container.name, newImage);
          container.image = newImage;
          images.push(newImage);
        }
      }

      // Delete fields that will make `registerTaskDefinition` unhappy.
      delete taskDefinition["taskDefinitionArn"];
      delete taskDefinition["revision"];
      delete taskDefinition["status"];
      delete taskDefinition["requiresAttributes"];

      // Register our updated task definition.
      ecs.registerTaskDefinition(taskDefinition, callback);
    },

    // Update our service to use the new task definition.
    (data, callback) => {
      const taskDefinition = data.taskDefinition;
      console.log("Updated task definition:", taskDefinition.taskDefinitionArn);
      const update = {
        cluster: ecsCluster,
        service: ecsService,
        taskDefinition: taskDefinition.taskDefinitionArn
      }
      ecs.updateService(update, callback);
    },

    // Return a summary of what we did.
    (data, callback) => {
      const service = data.service;
      console.log("Updated service:", service.serviceName, service.taskDefinition);
      callback(null, {
        cluster: ecsCluster,
        service: service.serviceName,
        taskDefinition: service.taskDefinition,
        images: images
      });
    }
  ], callback); // Pass results to the callback provided by AWS Lambda.
};
