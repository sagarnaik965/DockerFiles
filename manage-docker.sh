#!/bin/bash
DOCKER_RUN_SCRIPT="./docker-run-cmd.sh"


#echo "sh /home/sagar/Downloads/Docker/docker-installation/docker-installation.sh"
bash  /home/sagar/Downloads/Docker/docker-installation/docker-installation.sh

echo ""
echo "------------------------------------------------------------------------------"
echo ""

echo "Checking for required docker-images"
#echo "sh /home/sagar/Downloads/Docker/docker-deployment/check-docker-image.sh"
bash  /home/sagar/Downloads/Docker/docker-deployment/check-docker-image.sh

echo ""
echo "------------------------------------------------------------------------------"
echo ""


# Extract container name from docker run command
CONTAINER_NAME=$(grep -oP '(?<=--name )\S+' "$DOCKER_RUN_SCRIPT")

# Define required host paths with type (dir/file)
REQUIRED_PATHS=(
  "dir:/opt/appdata/docker-run/webapps/"
  "dir:/opt/appdata/logs"
)

# Ensure required host paths exist
for entry in "${REQUIRED_PATHS[@]}"; do
  type="${entry%%:*}"
  path="${entry#*:}"

  if [[ "$type" == "dir" ]]; then
    if [ ! -d "$path" ]; then
      echo "📁 Directory not found: $path"
      echo "➡️  Creating directory..."
      mkdir -p "$path"
    fi
  elif [[ "$type" == "file" ]]; then
    if [ ! -f "$path" ]; then
      echo "❌ Required file not found: $path"
      echo "Please ensure this file exists before starting the container."
      exit 1
    fi
  fi
done

# Check container existence and status
container_exists=$(docker ps -a --format '{{.Names}}' | grep -w "$CONTAINER_NAME")
container_running=$(docker ps --format '{{.Names}}' | grep -w "$CONTAINER_NAME")

if [ -z "$container_exists" ]; then
  echo "🆕 Container '$CONTAINER_NAME' not found."
  read -p "❓ Do you want to run the container using $DOCKER_RUN_SCRIPT? (y/n): " run_choice
  if [[ "$run_choice" == "y" || "$run_choice" == "Y" ]]; then
    echo "▶️ Running container..."
    $DOCKER_RUN_SCRIPT
  else
    echo "❌ Container was not started."
  fi
  # Refresh container state
  container_exists=$(docker ps -a --format '{{.Names}}' | grep -w "$CONTAINER_NAME")
  container_running=$(docker ps --format '{{.Names}}' | grep -w "$CONTAINER_NAME")
else
  echo "⚠️  Container '$CONTAINER_NAME' already exists."
  if [ "$container_running" ]; then
    echo "Status: RUNNING"
  else
    echo "Status: STOPPED"
  fi
fi

# Action menu loop
while true; do
  echo ""
  echo "Choose an action:"
  echo "1. Delete and start a new container"
  echo "2. Restart container"
  echo "3. Start (if stopped)"
  echo "4. Stop container"
  echo "5. Stop and delete container "
  echo "6. List of all containers "
  echo "7. Manage other containers"
  echo "8. Continue (exit menu)"
  read -p "Enter your choice [1-8]: " choice

  case $choice in
    1)
	  echo "##############Response###################"
      echo "➡️ Deleting and starting new container..."
      docker rm -f "$CONTAINER_NAME"
      $DOCKER_RUN_SCRIPT
      ;;
    2)
	  echo "##############Response###################"
      echo "➡️ Restarting container..."
      docker restart "$CONTAINER_NAME"
      ;;
    3)
	  echo "##############Response###################"
      if [ "$(docker ps --format '{{.Names}}' | grep -w "$CONTAINER_NAME")" ]; then
        echo "ℹ️ Container is already running."
      else
        echo "➡️ Starting container..."
        docker start "$CONTAINER_NAME"
      fi
      ;;
    4)
	  echo "##############Response###################"
      echo "➡️ Stopping container..."
      docker stop "$CONTAINER_NAME"
      ;;
    5)
	  echo "##############Response###################"
	  echo "🛑 Stopping and deleting container..."
      docker stop "$CONTAINER_NAME"
      docker rm "$CONTAINER_NAME"
     
      ;;
    6)
	  echo "##############Response###################"
      echo "List of all containers"
      docker ps -a
    
      ;;
    7)
	  echo "##############Response###################"
      echo ""
      echo "🔧 Manage other containers"
      docker ps -a --format "table {{.Names}}\t{{.Status}}"
      read -p "Enter container name to manage: " other_container
      if docker ps -a --format '{{.Names}}' | grep -wq "$other_container"; then
        echo "Actions for '$other_container':"
        echo "1. Stop"
        echo "2. Restart"
        echo "3. Stop and Delete"
        echo "4. Back to main menu"
        read -p "Choose an action [1-4]: " other_action
        case $other_action in
          1)
            docker stop "$other_container"
            ;;
          2)
            docker restart "$other_container"
            ;;
          3)
            docker stop "$other_container"
            docker rm "$other_container"
            ;;
          4)
            ;;
          *)
            echo "❌ Invalid action for other container."
            ;;
        esac
      else
        echo "❌ Container '$other_container' not found."
      fi
      ;;
    8)
	  echo "##############Response###################"
      echo "✅ Proceeding to next step..."
      break
      ;;
    *)
	  echo "##############Response###################"
      echo "❌ Invalid choice. Try again."
      ;;
  esac
done

echo ""
echo "📦 Currently running containers:"
docker ps

echo ""
read -p "📄 Do you want to view catalina logs? (y/n): " view_logs
if [[ "$view_logs" == "y" || "$view_logs" == "Y" ]]; then
  echo "📜 Tailing catalina.out logs..."
  tail -f /opt/appdata/logs/tomcatlogs/catalina.out -n 100
else
  echo "✅ Done."
fi
