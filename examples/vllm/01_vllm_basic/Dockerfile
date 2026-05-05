FROM registry.access.redhat.com/ubi9/python-312:latest

# set workdir
WORKDIR /app

# switch to root user
USER appuser

# set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    GRADIO_SERVER_NAME="0.0.0.0" \
    GRADIO_SERVER_PORT=7860 \
    GRADIO_TEMP_DIR="/tmp/gradio"

# copy requirements.txt and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# copy application source code
COPY chatapp.py .

# create non-root user
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app && \
    mkdir -p /tmp/gradio && \
    chown -R appuser:appuser /tmp/gradio

# switch to non-root user
USER appuser

# expose Gradio default port
EXPOSE 7860

# execute application
CMD ["python", "chatapp.py"]