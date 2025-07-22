import os

from google.cloud import pubsub_v1

GOOGLE_PROJECT_ID = 'holi-dev'

publisher = pubsub_v1.PublisherClient()
subscriber = pubsub_v1.SubscriberClient()

topics = ["okuna_local", "external-data-local"]

for topic in topics:
    topic_path = publisher.topic_path(GOOGLE_PROJECT_ID, topic)
    publisher.create_topic(request={"name": topic_path})
    print(f"Created Topic: {topic}")


def subscribe(service_name:str, to_topic_name: str, push_endpoint: str):
    subscription_name = subscriber.subscription_path(GOOGLE_PROJECT_ID, f"{service_name}-{to_topic_name}-sub")
    push_config = pubsub_v1.types.PushConfig(push_endpoint=push_endpoint)
    subscription = subscriber.create_subscription(
        request={
            "name": subscription_name,
            "topic": publisher.topic_path(GOOGLE_PROJECT_ID, to_topic_name),
            "push_config": push_config,
        },
    )
    print(f"Subscribed {service_name} to {to_topic_name} on {subscription.push_config.push_endpoint}")


subscribe('okuna',"external-data-local", "http://localhost:8000/pubsub/external-data-local/")

if os.getenv('LOCAL_BACKEND_CHAT') == "true":
    subscribe('chat-integration-service',"okuna_local", f"http://localhost:8088/projects/{GOOGLE_PROJECT_ID}/subscriptions/okuna_local")
