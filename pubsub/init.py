import os
from google.cloud import pubsub_v1

PUBSUB_PROJECT_ID = 'holi-dev'
PUBSUB_SUBSCRIBER_ENDPOINT = 'http://localhost'

chat_enabled = os.getenv('LOCAL_BACKEND_CHAT') == "true"

topic_names = ['okuna_local']
subscribers = []
if chat_enabled:
    print("Adding CHAT subscription")
    subscribers.append(['chat', 8088])

publisher = pubsub_v1.PublisherClient()

for topic_name in topic_names:
    topic_path = publisher.topic_path(PUBSUB_PROJECT_ID, topic_name)
    topic = publisher.create_topic(request={"name": topic_path})
    subscriber = pubsub_v1.SubscriberClient()
    print(f"Topic: {topic.name}")

    for sub in subscribers:
        subscription_path = subscriber.subscription_path(PUBSUB_PROJECT_ID, f"{sub[0]}-{topic_name}-sub")
        push_config = pubsub_v1.types.PushConfig(push_endpoint=f"{PUBSUB_SUBSCRIBER_ENDPOINT}:{sub[1]}/{topic_path}")

        subscription = subscriber.create_subscription(
            request={
                "name": subscription_path,
                "topic": topic_path,
                "push_config": push_config,
            }
        )

        print(f"Push subscription: {subscription.name}")
        print(f"Subscription endpoint: {subscription.push_config.push_endpoint}")
