# docker_cluster
A repository for creating docker files to be used on the CHTC startN

# build instruction
# docker build -t user_name/image_name:tag_name . (. is technically path to directory containing Dockerfile)
# if no tag is used, the tag latest will be applied to the image with the most recent build
docker build -t ligross/frensie_start_n:frensie_start_n .
docker build --no-cache -t ligross/frensie_start_n:frensie_start_n .

# run in interactive lmode with -i 
# docker container run -it [image id] or 
# you can use docker run -it <user>/repo:tag
docker run -it ligross/frensie_start_n:frensie_start_n

# run in interactive mode with a bind mount so that all data needed is in image
docker run -it --mount type=bind,source="/home/software/mcnpdata",target="/home/simulator/data/mcnpdata" ligross/frensie_start_n:frensie_start_n

# push instructions
docker push ligross/frensie_start_n:frensie_start_n