from http.client import responses

from locust import HttpUser, constant, task, between
import random

class WebsiteUser(HttpUser):
    wait_time = between(1, 3)
    #host = "https://api.podkapotom.kz" # back
    host = "https://podkapotom.kz" # front
    @task # main page - front начать с 400
    def load_home_page(self):
        self.client.get(f"/")
    @task # product page - front начать с 400
    def load_product_page(self):
        self.client.get(f"/product/yufi-nezamerzaiushhii-omyvatel-stekol-25s-4l-yufi-yf005-107148")
    @task  # category page - front начать с 400
    def load_category_page(self):
        self.client.get(f"/category/avtozapcasti")
    @task  # catalog page - front начать со 100
    def load_category_page(self):
        self.client.get(f"/catalog")
    @task  # terms page - front начать со 100
    def load_category_page(self):
        self.client.get(f"/terms")
    @task  # privacy page - front начать со 100
    def load_category_page(self):
        self.client.get(f"/privacy")
    @task  # about-company page - front начать со 100
    def load_category_page(self):
        self.client.get(f"/about-company")

