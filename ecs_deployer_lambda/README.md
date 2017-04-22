# AWS Lambda function to deploy ECS Services using CodePipeline

This is basically a much-simplified version
of [this AWS deployment idea][aws_version], but without any CloudFormation
involved, because that's just too many moving pieces for this project.  So
we do all the work with a tiny JavaScript run on AWS Lambda instead.

To rebuild it, run:

```sh
npm install -g yarn
yarn
npm run package
```

This will update the `ecs_deployer_lambda.zip` file in our parent
directory.

[aws_version]: https://aws.amazon.com/blogs/compute/continuous-deployment-to-amazon-ecs-using-aws-codepipeline-aws-codebuild-amazon-ecr-and-aws-cloudformation/
