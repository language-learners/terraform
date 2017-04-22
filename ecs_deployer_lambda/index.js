console.log('Loading');
const aws = require('aws-sdk');
const async = require('async');

// Export a handler to be called from ECS.
exports.handler = (event, context, callback) => {
  // Get our CodePipeline job information from the event.
  const job = event['CodePipeline.job'];
  console.log("Job:", job);

  // Fetch our `UserParameters`, parse them as JSON, and extract the values
  // we'll need.
  const params_json = job.data.actionConfiguration.configuration.UserParameters;
  const params = JSON.parse(params_json);
  const ecsCluster = params.ecsCluster;
  const ecsService = params.ecsService;
  const pipelineName = ecsService;
  const ecsRegion = params.ecsRegion;

  // Configure the AWS APIs that we'll need to use.
  const codepipeline = new aws.CodePipeline();
  const ecs = new aws.ECS({ region: ecsRegion });

  // Declare some variables we want to pass between stages of our
  // "waterfall," below.
  const images = [];
  let imageTag;
  let summary;

  // Use `async.waterfall` to run a chained series of callbacks, giving up
  // early if there's an error.
  async.waterfall([

    // Get our git commit ID.
    (callback) => {
      codepipeline.getPipelineState({ "name": pipelineName }, callback);
    },

    // Save our git commit ID as our image tag, and look up our ECS service.
    (data, callback) => {
      console.log("Stage info:", data.stageStates[0].actionStates[0]);
      imageTag = data.stageStates[0].actionStates[0].currentRevision.revisionId;
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

    // Summarize what we did, and attempt to tell CodePipeline about it.
    (data, callback) => {
      const service = data.service;
      summary = {
        cluster: ecsCluster,
        service: service.serviceName,
        taskDefinition: service.taskDefinition,
        images: images
      };
      console.log("Updated service:", summary);
      codepipeline.putJobSuccessResult({ jobId: job.id }, callback);
    }
  ], (err, result) => { // Handle the result of our waterfall.
    if (err) {
      // We failed somewhere, so report it to CodePipeline.
      console.log("Error:", err, err.stack);
      const failure = {
        jobId: job.id,
        failureDetails: {
          message: JSON.stringify(err),
          type: 'JobFailed',
          externalExecutionId: context.invokeid
        }
      };
      codepipeline.putJobFailureResult(failure, callback);
    } else {
      console.log("Success");
      // We succeeded, so return our summary.
      callback(null, summary);
    }
  });
};
