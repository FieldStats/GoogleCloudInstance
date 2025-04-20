FROM python:3.10-slim

# For GPU support 
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libgl1-mesa-glx \
    libglib2.0-0 \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy requirements file
COPY requirements.txt .

# Update pip first
RUN pip install --upgrade pip

# Install Python dependencies with error handling
RUN pip install --no-cache-dir -r requirements.txt || \
    (echo "Attempting installation with compatibility fixes..." && \
     pip install --no-cache-dir --use-pep517 -r requirements.txt || \
     (sed -i 's/==/>=/g' requirements.txt && pip install --no-cache-dir -r requirements.txt))

# Install API dependencies
RUN pip install --no-cache-dir fastapi uvicorn

# Copy source code
COPY *.py .
COPY *.txt .

# Expose API port
EXPOSE 8000

# Command to run the API server
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
