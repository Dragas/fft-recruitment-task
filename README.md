# Infrastructure test assignment

We have created infrastructure and app for a basic web site using Amazon Web Services - it is a static site deployed in an S3 bucket and served by CloudFront. Your task will be to make some infrastructure-level changes to support experiments.

## Your task

- Create or use an existing personal AWS account
- Add the credits as recieved separately
- Deploy the infrastructure in infrastructure-task folder using Terraform (terraform init && terraform apply)
- Copy the static app in the app folder to the created S3-bucket
- Familiarize yourself with the "application"
- Notice that the "home" page has two other variants `home/variant-1` and `home/variant-2` which are currently unused
- Implement _infrastructure-level_ logic that will randomly distribute traffic to the "home" page between the different variants (`home`, `home/variant-1`, and `home/variant-2`)
- Depending on how much time you have, there are some possible extensions:
  - Prevent users from accessing the other variants by going directly to the corresponding URL. `/home` should lead to the assigned variant, `/home/variant-1` and `/home/variant-2` should not work.
  - Add a way for developers (etc.) to access a specific variant (maybe a cookie or other header, or a URL parameter)
  - Make the distribution "sticky" so that a particular user always gets the same variant
  - Add a way to quickly turn the "experiment" on or off without deploying new code. When off, visitors should always get the original version
  - Add a way to quickly (without deploying new code) select a variant that will be used for all traffic

You should not have time to implement everything, but we would like to discuss your ideas during the technical interview even if you do not finish them.

At Telia we manage our infrastructure as code using Terraform, but for this task you can use any tool you like, or make changes manually. Parts of the task could be implemented by changing the (frontend) application rather than the infrastructure, but for the purposes of this assignment, please do not change the application code.

## Tips

- There is already a Lambda@Edge function that handles incoming requests. This could be a good place to start, but you may choose a different solution if you want
- AWS has good developer documentation. The most relevant parts is likely the [CloudFront Developer Guide](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Introduction.html).
- The existing infrastructure is set up using Terraform. You can see the templates in this repository, and if you want to you can continue using Terraform to modify it.

**Good luck!**
