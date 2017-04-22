console.log('Loading');
var aws = require('aws-sdk');

exports.handler = (event, context, callback) => {
    var ecsCluster = 'language-learners';
    var ecsService = 'phpbb';
    var ecsRegion = 'us-east-1';
    var imageTag = '7c05000a-a357-483d-a839-cedd3b0031a3';

    // Call this function with an error if we fail.
    function fail(err) {
        console.log(err, err.stack);
        callback(err, null);
    }

    var ecs = new aws.ECS({region: ecsRegion});
    ecs.describeServices({cluster: ecsCluster, services:[ecsService]}, function (err, data) {
        if (err) {
            fail(err);
        } else {
            var service = data.services[0];
            //console.log("service:", service);
            ecs.describeTaskDefinition({taskDefinition: service.taskDefinition}, function (err, data) {
                if (err) {
                    fail(err);
                } else {
                    var taskDefinition = data.taskDefinition;
                    //console.log("taskDefinition:", taskDefinition);
                    var images = [];
                    for (var container of taskDefinition.containerDefinitions) {
                        if (container.name === ecsService) {
                            //console.log(container);
                            var newImage = container.image.replace(/:([^:]*)$/, ":" + imageTag);
                            console.log("Updating container to use new image:", container.name, newImage);
                            container.image = newImage;
                            images.push(newImage);
                        }
                    }
                    delete taskDefinition["taskDefinitionArn"];
                    delete taskDefinition["revision"];
                    delete taskDefinition["status"];
                    delete taskDefinition["requiresAttributes"];
                    ecs.registerTaskDefinition(taskDefinition, function (err, data) {
                        if (err) {
                            fail(err);
                        } else {
                            var taskDefinition = data.taskDefinition;
                            console.log("Updated task definition:", taskDefinition.taskDefinitionArn);
                            var update = {
                                cluster: ecsCluster,
                                service: ecsService,
                                taskDefinition: taskDefinition.taskDefinitionArn
                            }
                            ecs.updateService(update, function (err, data) {
                                if (err) {
                                    fail(err);
                                } else {
                                    var service = data.service;
                                    console.log("Updated service:", service.serviceName, service.taskDefinition);
                                    callback(null, {
                                        cluster: ecsCluster,
                                        service: service.serviceName,
                                        taskDefinition: service.taskDefinition,
                                        images: images
                                    });
                                }
                            });
                        }
                    })
                }
            });
        }
    });
};
