from flask import Flask, request, jsonify
from google import genai
from google.genai import types
from os import getenv
import json
import base64
import asyncio
import aiohttp
from urllib.parse import urlencode

app = Flask(__name__)


# Geminiにより題材や物語等のテキストを作成する。
async def generate_text(prompt, temperature, response_schema):
    model = "gemini-2.0-flash-exp"
    client = genai.Client(
        vertexai=True, project=getenv("PROJECT_ID"), location=getenv("LOCATION")
    )

    contents = [types.Content(role="user", parts=[types.Part.from_text(text=prompt)])]

    generate_content_config = types.GenerateContentConfig(
        temperature=temperature,
        top_p=0.95,
        max_output_tokens=8192,
        response_modalities=["TEXT"],
        safety_settings=[
            types.SafetySetting(
                category="HARM_CATEGORY_HATE_SPEECH", threshold="BLOCK_LOW_AND_ABOVE"
            ),
            types.SafetySetting(
                category="HARM_CATEGORY_DANGEROUS_CONTENT",
                threshold="BLOCK_LOW_AND_ABOVE",
            ),
            types.SafetySetting(
                category="HARM_CATEGORY_SEXUALLY_EXPLICIT",
                threshold="BLOCK_LOW_AND_ABOVE",
            ),
            types.SafetySetting(
                category="HARM_CATEGORY_HARASSMENT", threshold="BLOCK_LOW_AND_ABOVE"
            ),
        ],
        response_mime_type="application/json",
        response_schema=response_schema,
        system_instruction="You are a professional picture book creator with 20 years of experience. You specialize in creating illustration-style picture books targeted at children ages 3 to 12. A characteristic of your picture books is the inclusion of lessons and morals.",
    )

    # 最大3回まで試行する。
    for i in range(3):
        try:
            response = await client.aio.models.generate_content(
                model=model,
                contents=contents,
                config=generate_content_config,
            )
            return response.text
        except Exception as e:
            exception_message = e.args[0]
            print(e)
            if "429 RESOURCE_EXHAUSTED" in exception_message:
                await asyncio.sleep(3)
            else:
                raise e
    raise Exception("最大試行回数を超過しました。テキスト生成に失敗しました。")


# 画像を生成する。
async def generate_image(imagen_prompt):
    model = "imagen-3.0-generate-001"
    client = genai.Client(
        vertexai=True, project=getenv("PROJECT_ID"), location=getenv("LOCATION")
    )

    # 最大3回まで試行する。
    for i in range(3):
        try:
            image = await client.aio.models.generate_images(
                model=model,
                prompt=imagen_prompt,
                config=types.GenerateImagesConfig(
                    aspect_ratio="1:1",
                    number_of_images=1,
                    language="ja",
                    include_rai_reason=False,
                    output_mime_type="image/jpeg",
                    safety_filter_level="block_low_and_above",
                    person_generation="allow_all",
                ),
            )

            image_bytes = image.generated_images[0].image.image_bytes
            image_str = base64.b64encode(image_bytes).decode("utf-8")

            return image_str
        except Exception as e:
            exception_message = e.args[0]
            print(e)
            if "429 RESOURCE_EXHAUSTED" in exception_message:
                await asyncio.sleep(3)
            elif "'NoneType' object is not subscriptable" in exception_message:
                await asyncio.sleep(3)
                prompt = f"""
                Please remove the references to people from the following text.
                Do not change the context of the text.
                '{imagen_prompt}'
                """
                temperature = 1
                response_schema = {
                    "type": "OBJECT",
                    "required": ["imagen_prompt"],
                    "properties": {
                        "imagen_prompt": {
                            "type": "STRING",
                            "description": "Revised text",
                        },
                    },
                }
                response = await generate_text(
                    imagen_prompt, temperature, response_schema
                )
                imagen_prompt = json.loads(response)["imagen_prompt"]
                continue
            else:
                raise e
    raise Exception("最大試行回数を超過しました。画像生成に失敗しました。")


# ずんだもんの音声を作成する。
async def generate_audio(text):
    voicevox_url = "https://deprecatedapis.tts.quest/v2/voicevox/audio/"

    async with aiohttp.ClientSession() as session:
        voicevox_api_key = getenv("VOICEVOX_API_KEY")
        url = f"{voicevox_url}/?key={voicevox_api_key}&speaker=1&pitch=0&intonationScale=1&speed=1.2"
        query_param = {"text": text}
        encoded_param = urlencode(query_param)
        full_url = f"{url}&{encoded_param}"

        async with session.post(full_url, data=None) as response:
            audio_bytes = await response.read()

    audio_str = base64.b64encode(audio_bytes).decode("utf-8")

    return audio_str


# 題材を生成する。
@app.route("/select-main-theme", methods=["POST"])
async def select_main_theme():
    main_theme = request.json.get("mainTheme", "")
    prompt = f"""
    Please suggest six settings suitable for a picture book based on the following theme/topic.
    Keep the setting descriptions short and simple, and appropriate for children ages 3-12.
    The suggestions must be in Japanese.

    Theme: {main_theme}

    Example answer:
    {{
      "stages": [
        "ロボットの心のぼうけん",
        "ようせいの住む庭",
        "月明かりの森の音楽会",
        "時間が止まった古い時計塔",
        "不思議な森の小さな冒険",
        "夜になるとおもちゃたちが動き出す古いおもちゃ屋さん"
      ]
    }}
    """

    response_schema = {
        "type": "OBJECT",
        "required": ["stages"],
        "properties": {
            "stages": {
                "type": "ARRAY",
                "description": "List of stages",
                "items": {"type": "STRING", "description": "Stage name"},
            },
        },
    }

    temperature = 1
    results = await generate_text(prompt, temperature, response_schema)

    return jsonify(results)


# 大人向けに物語を生成する。
@app.route("/generate-story-parent", methods=["POST"])
async def generate_story_parent():
    subject = request.json.get("subject", "ランダム")
    stage = request.json.get("stage", "ランダム")
    genres = request.json.get("genres", "ランダム")
    protagonist_type = request.json.get("protagonistType", "動物")
    protagonist_name = request.json.get("protagonistName", "ランダム")
    target_age = request.json.get("targetAge", "5")
    duration = request.json.get("duration", "3")
    text_style = request.json.get("textStyle", "ひらがな")
    purpose = request.json.get("purpose", "道徳や教訓を学ぶため")

    prompt = f"""
    Please answer in Japanese without fail.
    Please create a children's picture book story based on the following criteria:
    Story Criteria:
    - Educational Theme: {subject}
    - Setting: {stage}
    - Genre(s): {",".join(genres)}
    - Protagonist Type: {protagonist_type}
    - Protagonist Name: {protagonist_name} (Note: The protagonist's age should be ambiguous and not explicitly defined.)
    - Target Audience: {target_age} (Describe the target audience in terms of maturity level and interests, rather than specific age ranges. For example, "early learners," "those interested in problem-solving," etc.)
    - Total Word Count (Entire Story): {duration * 400}
    - Text Style: {text_style}
    - Purpose of the Story: {purpose}
    - Structure: Kishotenketsu (Four-act structure: Introduction, Development, Twist, Conclusion)

    Image Prompt Criteria (for insertion into the picture book):
    - Do not include any words or references related to children, youth, or childhood in the generated image prompts.
    - No sexual depictions.
    - Must be in English.
    - The illustrations must differ for each of the four acts (Kishotenketsu).
    - The appearance of characters and illustration style should be consistent across all four acts.
    - Do not use illustrations modeled after real-life animals or people.
    - Emphasize originality and avoid any resemblance to existing copyrighted characters or intellectual properties. All designs and characters must be unique and original creations.
    - The character designs should be generic and non-distinct, avoiding specific traits or features that could be associated with any particular copyrighted character.
    - Negative Prompt (for image generation):
    - child, youth, kid, school, park, playground, age, years old, boy, girl, baby, toddler, infant, classroom, teacher, student, uniform, toy, play, childhood
    - Illustration in a painterly style, emphasizing soft, blended colors, and a dreamlike atmosphere. Focus on creating a sense of wonder and serenity through subtle details and expressive characters. The aim is to evoke a feeling of nostalgia and warmth.
    - Color Palette: Primarily warm and natural tones, with a focus on creating a sense of harmony and balance. Use a limited palette to maintain a consistent and cohesive look. Dominant colors should include soft blues, greens, browns, and creams.
    - Lighting: Soft, diffused light that gently illuminates the scene, creating subtle shadows and highlights. The lighting should contribute to the overall sense of warmth and peacefulness. Aim for a light source that feels natural and inviting.
    - Linework: Avoid sharp, defined lines. Instead, use soft, blurred edges to create a sense of softness and ethereal quality. Think of watercolor or gouache techniques.
    - Overall Style: The illustration should capture a specific aesthetic characterized by its painterly qualities, expressive character designs, and atmospheric rendering. Strive for a sense of depth and dimension through the use of color and light. Avoid overly realistic textures or harsh contrasts. Aim for a slightly idealized and romanticized depiction of the subject matter. Focus on creating a visually appealing and emotionally resonant image.
    - Emphasis: Focus on the painterly techniques, the expressive use of light and color, and the overall dreamlike quality of the image. The key is to capture a specific "feel" or mood, rather than replicating any particular artist or style.

    Example answer:
    {{
      "title": "Story Title",
      "scenes": [
        {{
          "description": "Scene Description",
          "text": "Scene Text",
          "imagenPrompt": "Image Prompt",
          "order": "Scene Order (Numerical)"
        }}
      ]
    }}
    """

    response_schema = {
        "type": "OBJECT",
        "required": ["title", "scenes"],
        "properties": {
            "title": {"type": "STRING", "description": "Story title"},
            "scenes": {
                "type": "ARRAY",
                "description": "Story scenes",
                "items": {
                    "type": "OBJECT",
                    "required": ["description", "text", "imagenPrompt", "order"],
                    "properties": {
                        "description": {
                            "type": "STRING",
                            "description": "Scene description",
                        },
                        "text": {"type": "STRING", "description": "Scene text"},
                        "imagenPrompt": {
                            "type": "STRING",
                            "description": "Image prompt",
                        },
                        "order": {
                            "type": "NUMBER",
                            "description": "Scene order (numerical)",
                        },
                    },
                },
            },
        },
    }

    temperature = 1
    generated_texts = await generate_text(prompt, temperature, response_schema)
    generated_texts_dict = json.loads(generated_texts)
    loop = asyncio.get_event_loop()
    image_generation_tasks = [
        generate_image(scene["imagenPrompt"])
        for scene in generated_texts_dict["scenes"]
    ]
    images = await asyncio.gather(*image_generation_tasks)
    for i, scene in enumerate(generated_texts_dict["scenes"]):
        generated_texts_dict["scenes"][i]["imageStr"] = images[i]

    audio_generation_tasks = [
        generate_audio(scene["text"]) for scene in generated_texts_dict["scenes"]
    ]
    audios = await asyncio.gather(*audio_generation_tasks)
    for i, scene in enumerate(generated_texts_dict["scenes"]):
        generated_texts_dict["scenes"][i]["audioStr"] = audios[i]

    return jsonify(generated_texts_dict)


# 子供向けに物語を生成する。
@app.route("/generate-story-child", methods=["POST"])
async def generate_story_child():
    genres = request.json.get("genres", "動物")
    target_age = request.json.get("targetAge", "5")
    duration = request.json.get("duration", "3")
    text_style = request.json.get("textStyle", "ひらがな")
    purpose = request.json.get("purpose", "道徳や教訓を学ぶため")

    prompt = f"""
    Please answer in Japanese without fail.
    Please create a children's picture book story based on the following criteria:
    Story Criteria:
    - Educational Theme: Choose one from "日常の出来事, 自然や動物, 心や感情の成長, 冒険とファンタジー, 教育的なテーマ, 社会や道徳のテーマ, ユーモアやナンセンス, 夢や想像力を刺激するテーマ, 人生のターニングポイント, 地域や文化".
    - Setting: Set one stage. For example, "ロボットの心のぼうけん, ようせいの住む庭, 月明かりの森の音楽会, 時間が止まった古い時計塔, 不思議な森の小さな冒険, 夜になるとおもちゃたちが動き出す古いおもちゃ屋さん"
    - Genre(s): {",".join(genres)}
    - Target Age: {target_age}
    - Total Word Count (Entire Story): {duration * 400}
    - Text Style: {text_style}
    - Purpose of the Story: {purpose}
    - Structure: Kishotenketsu (Four-act structure: Introduction, Development, Twist, Conclusion)

    Image Prompt Criteria (for insertion into the picture book):
    - Do not include any words or references related to children, youth, or childhood in the generated image prompts.
    - No sexual depictions.
    - Must be in English.
    - The illustrations must be different for each of the four acts (Kishotenketsu).
    - The appearance of characters and illustration style should be consistent across all four acts.
    - Do not use illustrations modeled after real-life animals or people.
    - Negative Prompt (for image generation):
    - child, youth, kid, school, park, playground, age, years old, boy, girl, baby, toddler, infant, classroom, teacher, student, uniform, toy, play, childhood
    - Illustration in a painterly style, emphasizing soft, blended colors, and a dreamlike atmosphere. Focus on creating a sense of wonder and serenity through subtle details and expressive characters. The aim is to evoke a feeling of nostalgia and warmth.
    - Color Palette: Primarily warm and natural tones, with a focus on creating a sense of harmony and balance. Use a limited palette to maintain a consistent and cohesive look. Dominant colors should include soft blues, greens, browns, and creams.
    - Lighting: Soft, diffused light that gently illuminates the scene, creating subtle shadows and highlights. The lighting should contribute to the overall sense of warmth and peacefulness. Aim for a light source that feels natural and inviting.
    - Linework: Avoid sharp, defined lines. Instead, use soft, blurred edges to create a sense of softness and ethereal quality. Think of watercolor or gouache techniques.
    - Overall Style: The illustration should capture a specific aesthetic characterized by its painterly qualities, expressive character designs, and atmospheric rendering. Strive for a sense of depth and dimension through the use of color and light. Avoid overly realistic textures or harsh contrasts. Aim for a slightly idealized and romanticized depiction of the subject matter. Focus on creating a visually appealing and emotionally resonant image.
    - Emphasis: Focus on the painterly techniques, the expressive use of light and color, and the overall dreamlike quality of the image. The key is to capture a specific "feel" or mood, rather than replicating any particular artist or style.

    When creating a story, please keep the following points in mind.
    Points to note:
    - Use easy-to-understand words.
    - Express yourself in short sentences.
    - Make the content fun and uplifting.
    - Include good morals or lessons.
    - Use plenty of hiragana."

    Example answer:
    {{
      "title": "Story Title",
      "scenes": [
        {{
          "description": "Scene Description",
          "text": "Scene Text",
          "imagenPrompt": "Image Prompt",
          "order": "Scene Order (Numerical)"
        }}
      ]
    }}
    """

    response_schema = {
        "type": "OBJECT",
        "required": ["title", "scenes"],
        "properties": {
            "title": {"type": "STRING", "description": "Story title"},
            "scenes": {
                "type": "ARRAY",
                "description": "Story scenes",
                "items": {
                    "type": "OBJECT",
                    "required": ["description", "text", "imagenPrompt", "order"],
                    "properties": {
                        "description": {
                            "type": "STRING",
                            "description": "Scene description",
                        },
                        "text": {"type": "STRING", "description": "Scene text"},
                        "imagenPrompt": {
                            "type": "STRING",
                            "description": "Image prompt",
                        },
                        "order": {
                            "type": "NUMBER",
                            "description": "Scene order (numerical)",
                        },
                    },
                },
            },
        },
    }

    temperature = 0
    generated_texts = await generate_text(prompt, temperature, response_schema)
    generated_texts_dict = json.loads(generated_texts)
    loop = asyncio.get_event_loop()
    image_generation_tasks = [
        generate_image(scene["imagenPrompt"])
        for scene in generated_texts_dict["scenes"]
    ]
    images = await asyncio.gather(*image_generation_tasks)
    for i, scene in enumerate(generated_texts_dict["scenes"]):
        generated_texts_dict["scenes"][i]["imageStr"] = images[i]

    audio_generation_tasks = [
        generate_audio(scene["text"]) for scene in generated_texts_dict["scenes"]
    ]
    audios = await asyncio.gather(*audio_generation_tasks)
    for i, scene in enumerate(generated_texts_dict["scenes"]):
        generated_texts_dict["scenes"][i]["audioStr"] = audios[i]

    return jsonify(generated_texts_dict)
