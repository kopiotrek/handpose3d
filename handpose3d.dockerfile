FROM ubuntu:20.04
ENTRYPOINT ["/bin/bash"]

# Set timezone environment variable to prevent interactive prompt
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Update and install necessary packages
RUN DEBIAN_FRONTEND=noninteractive \
  apt-get update \
  && apt-get install -y g++ software-properties-common wget git curl nano

# Cuda drivers installation
RUN DEBIAN_FRONTEND=noninteractive \
  && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  tee /etc/apt/sources.list.d/nvidia-container-toolkit.list \
  && apt-get install -y nvidia-cuda-toolkit 

# ROS noetic install
RUN DEBIAN_FRONTEND=noninteractive \
  && sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list' \
  && curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add - \
  && apt-get update

RUN DEBIAN_FRONTEND=noninteractive \
  && echo 'keyboard-configuration keyboard-configuration/layoutcode string us' | debconf-set-selections \
  && apt-get install -y ros-noetic-desktop-full

RUN DEBIAN_FRONTEND=noninteractive \
  && echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc \
  && apt install -y python3-importlib-metadata python3-rosdep python3-rosinstall python3-rosinstall-generator python3-wstool build-essential \
  && rosdep init \
  && rosdep update -y

# Install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
  && chmod +x Miniconda3-latest-Linux-x86_64.sh \
  && ./Miniconda3-latest-Linux-x86_64.sh -b -p /opt/conda

# Update PATH for Conda
ENV PATH="/opt/conda/bin:$PATH"

# Clone the GitHub repository
# RUN git clone https://github.com/TemugeB/handpose3d.git
# RUN git clone https://github.com/TemugeB/python_stereo_camera_calibrate

COPY env_handpose3d.yml /handpose3d/env_handpose3d.yml
RUN cd handpose3d && conda env create -f env_handpose3d.yml
SHELL ["conda", "run", "-n", "handpose3d", "/bin/bash", "-c"]
RUN conda init
RUN echo "conda activate handpose3d" >> ~/.bashrc

# Clean up
# RUN rm -rf /var/lib/apt/lists/*
