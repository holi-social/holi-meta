from google.cloud import pubsub_v1

PUBSUB_PROJECT_ID = 'holi-dev'
PUBSUB_SUBSCRIBER_ENDPOINT = 'http://localhost:8086'

topic_names = ['okuna_development']

publisher = pubsub_v1.PublisherClient()

for topic_name in topic_names:    
    topic_path = publisher.topic_path(PUBSUB_PROJECT_ID, topic_name)
    topic = publisher.create_topic(request={"name": topic_path})
    
    print(f"Topic: {topic.name}")

    subscriber = pubsub_v1.SubscriberClient()
    subscription_path = subscriber.subscription_path(PUBSUB_PROJECT_ID, f"{topic_name}-sub")

    push_config = pubsub_v1.types.PushConfig(push_endpoint=PUBSUB_SUBSCRIBER_ENDPOINT)

    with subscriber:
        subscription = subscriber.create_subscription(
            request={
                "name": subscription_path,
                "topic": topic_path,
                "push_config": push_config,
            }
        )

    print(f"Push subscription: {subscription.name}")
    print(f"Subscription endpoint: {subscription.push_config.push_endpoint}")