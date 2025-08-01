# Kubernetes Assignment - Jamf DevOps Engineer II (Kubernetes) Technical Interview

## Overview - What We Are Looking For

This task is designed to see how you approach deploying the types of systems that our Kube teams encounter on a regular basis. We appreciate that this interview step takes time and energy, and we thank you for letting us see your best work in action. Please feel free to use supplementary resources, but please share in the work demonstration (see below) what resources you consulted to complete this work. Your problem-solving process is as much a part of this interview stage as is the product you build.

## Alternate Options

Our goal is to see how you approach the following tasks. If you have existing work in a public GitHub that you can share which demonstrates these skills, please feel free to utilize that, although take care that you can address all the competencies outlined below.

## Task Outline

You may use any Kubernetes platform or provider for the following work, however Jamf uses Amazon EKS.

1. Deploy a cluster with at least two nodes: one control plane and at least one worker.

2. Deploy a simple application that has multiple services and components, such as WordPress. Expose the application so that it can be accessed from outside the cluster, such as from a browser or terminal on localhost. Note: if you are running your Kube locally, it does not have to be publicly accessible-- just accessible from your local machine.

3. Define resource limits for the namespace. You can determine what these limits should be, but please explain in your show and tell (below) what limits you chose and why you set them where you did, as well as how you would configure this differently for high availability. Configure autoscaling so that the resource limits you defined will trigger scaling pods up and down when appropriate.

4. Once your deployment is finished, create a Terraform configuration and Helm chart which would replicate your deployment.

## Demonstration of Work

We will schedule a two-hour demonstration session with some of our engineering staff. During this session, you can demonstrate your product and explain your process. The first 30 minutes are reserved for you to “show and tell.” Some things that you might include, which are of particular interest to us, are:

- What problems did you encounter in this work, and how did you overcome them?

- What resources did you use to complete the work, and how did you research any necessary information?

- How would you configure your application for high availability?

- What is the difference, if any, between deploying this configuration with Terraform
and Helm versus a plain Kubernetes manifest?

- If any of the tools you used in this work are new to you, what other similar tools have you used in the past, and what differences could you describe between our tooling and your past tools?

- Are there any security vulnerabilities you see in your deployment? What steps would you take to harden this deployment if you were running it in a large enterprise setting?

You are not required to prepare slides, although you may do so if you wish. Please plan on sharing and explaining any relevant code examples as part of your presentation.
