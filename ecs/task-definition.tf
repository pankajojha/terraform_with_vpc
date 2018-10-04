data "aws_ecs_task_definition" "star-app" {
  task_definition = "${aws_ecs_task_definition.star-app.family}"
}

resource "aws_ecs_task_definition" "star-app" {
    family                = "hello_world"
    container_definitions = <<DEFINITION
[
  {
    "name": "star-app",
    "links": [
      "mysql"
    ],
    "image": "star-app",
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ],
    "memory": 500,
    "cpu": 10
  },
  {
    "environment": [
      {
        "name": "MYSQL_ROOT_PASSWORD",
        "value": "password"
      }
    ],
    "name": "mysql",
    "image": "mysql",
    "cpu": 10,
    "memory": 500,
    "essential": true
  }
]
DEFINITION
}