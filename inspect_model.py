import tensorflow as tf
interpreter = tf.lite.Interpreter(model_path='assets/best.tflite')
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()
print('Inputs:')
for i in input_details: 
    print(f"- {i['name']}: shape={i['shape']} type={i['dtype']}")
print('Outputs:')
for o in output_details: 
    print(f"- {o['name']}: shape={o['shape']} type={o['dtype']}")
