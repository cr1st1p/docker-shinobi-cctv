## Shinobi CCTV Docker image

### Motivation

This is an image with https://shinobi.video/ - an Open Source CCTV Solution

There is already an official image from the company behind Shinobi, at https://hub.docker.com/r/shinobicctv/shinobi . 
Read below about the differences in order to see which one might fit your needs.


Code will be retrieved, during build, from branch 'dev'



### Differences


The differences come from the fact that this should generate an image that can be integrated into a Kubernetes cluster, and that it will contain only the CCTV related processes - no mysql setup for example.

- build is different
- container's purpose is to be used in a Kubernetes cluster
- no incorporated Mysql server - leave it as an external dependency
--It expects the information to be provided directly into the configuration file ```conf.json```
  - it also expects the database and the user to be created already
- configuration file, *conf.json* and *super.json* would be generated from a *configmap*, inside a Kubernetes install
- image size is smaller: 520Mb versus 1.3Gb. 
- image size was also one of the reasons for using [dockerfile-lib](https://github.com/cr1st1p/dockerfile-lib)



### Runtime configuration

At runtime,  you will need to have:

-  2 configuration files generated and mounted into the docker image
- a volume for storing video recordings be mounted at */opt/shinobi/videos*



### Kubernetes install

An example of a Kubernetes install can be found in the directory *kubernetes/*

### Docker-compose run

You can run this image also in a *docker-compose* style - please check the directory *test/*  and section 'Quick run' below.



### If features are not working...

There are few things that are not installed, compared to the other docker image - mostly build tools and some libraries - I didn't feel they were needed. But I also did not test any plugins. 

If something will not work for you, maybe comment the ```return 0``` from function ``run_shinobi_install_package_dependencies()``	and try with that new image.



### Security

If you care about who can access your video streams or recording, then you should use HTTPS and not plain HTTP. Using this image inside a Kubernetes cluster with cert-manager for example should be reasonably easy.

Additionally, I would also add some form of Http authentication,  in **addition** to what shinobi does (it might not do account checks everywhere). It should be simple to edit an ingress record inside Kubernetes.



### Accessing from outside your network environment

You must first check the Security section above, and implement http**S** **and** additional http authentication. Without those, I would not expose the software to outside world.

You will probably also have to do some port forwarding into your router + dynamic DNS (search for more details on the net)



### Building the image

The building of this image uses the small "framework" from dockerfile-lib, as a *git submodule*

As such, after cloning this repository, you will need to run

```shell
git submodule init
git submodule update
```

For more details and information on how to write your functions please read that repository's README.md file



### Quick run

In directory `test/` there is a *docker-compose* setup, for testing/previewing purposes.

Depending on your needs you might want to generate the 'dev' mode Dockerfile (it allows you to do faster rebuilds):

```shell
./build.sh --dev
```



```shell
cd test
docker-compose up
```

First time, mysql data needs to be created, so you'll need to wait 20-30 seconds. When you see log lines suggesting both mysql and shinobi started ok, you can access the web interface.

Goto http://localhost:8081/super  - enter `admin@shinobi.video` and `admin` Create a user, then log in as that user, at http://localhost:8081/, add a camera and ... enjoy!



### License

The code from this repository - aka the build system, is licensed [Apache 2.0](LICENSE). The Shinobi code has a different open source license: https://gitlab.com/Shinobi-Systems/Shinobi/-/blob/master/LICENSE.md


### TODO

don't run as 'root'
