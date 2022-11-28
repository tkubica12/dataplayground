- [Serving models](#serving-models)
  - [Streaming example](#streaming-example)

# Serving models
MLFlow provides easy way to server models as REST API. It will create single-node cluster dedicated to this model.

This might be overkill if you have a lot of small models - eg. situation when you create one model per customer, device etc. 

In public preview Databricks introduced **Serverless Real-Time Inference** feature.

Another way is to add custom code to your model using MLFlow pyfunc that would work as "router" point to correct model based on customer_id, device_id etc.

```python
device_to_model = {row["device"]: mlflow.sklearn.load_model(f"runs:/{row['run_id']}/{row['device']}") for row in model_df.collect()}

from mlflow.pyfunc import PythonModel

class OriginDelegatingModel(PythonModel):
    
    def __init__(self, device_to_model_map):
        self.device_to_model_map = device_to_model_map
        
    def predict_for_device(self, row):
        '''
        This method applies to a single row of data by
        fetching the appropriate model and generating predictions
        '''
        model = self.device_to_model_map.get(str(row["device_id"]))
        data = row[["feature_1", "feature_2", "feature_3"]].to_frame().T
        return model.predict(data)[0]
    
    def predict(self, model_input):
        return model_input.apply(self.predict_for_device, axis=1)

with mlflow.start_run():
    model = OriginDelegatingModel(device_to_model)
    mlflow.pyfunc.log_model("model", python_model=model)
```

Note this is where Azure ML might provide more robust solution:
- Package to Kubernetes or run as managed online endpoints with monitoring, logging, VNET integration, AAD authentication
- Supports other formats such as Triton for high-performance serving including GPU accelerated inferencing using TensorFlow, ONNX Runtime, PyTorch or NVIDIA TensorRT
- Easily deploy ONNX models
- Prebuild and maintained Docker images for serving models for running models anywhere (IoT edge, on-prem, cloud)

## Streaming example
You can call transform method on streaming table.

```python
# Get stream
streaming_data = (spark
                 .readStream
                 .schema(schema) # Can set the schema this way
                 .option("maxFilesPerTrigger", 1)
                 .parquet(repartitioned_path))

# Score stream
stream_pred = pipeline_model.transform(streaming_data)

# Export stream
import re

checkpoint_dir = f"{DA.paths.working_dir}/stream_checkpoint"
# Clear out the checkpointing directory
dbutils.fs.rm(checkpoint_dir, True) 

query = (stream_pred.writeStream
                    .format("memory")
                    .option("checkpointLocation", checkpoint_dir)
                    .outputMode("append")
                    .queryName("pred_stream")
                    .start())

# Read data
%sql 
select * from pred_stream
```