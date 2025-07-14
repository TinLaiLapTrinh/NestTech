from django.utils.safestring import mark_safe

text_color = {
    "red": " text-red dark:text-red",
    "green": " text-green dark:text-green",
    "blue": " text-blue dark:text-blue",
    "yellow": " text-yellow dark:text-yellow",
    "pink": " text-pink dark:text-pink",
    "purple": " text-purple dark:text-purple",
    "teal": " text-teal dark:text-teal",
    "gray": " text-gray dark:text-gray",
}

bg_color = {
    "red": " bg-red dark:bg-red",
    "green": " bg-green dark:bg-green",
    "blue": " bg-blue dark:bg-blue",
    "yellow": " bg-yellow dark:bg-yellow",
    "pink": " bg-pink dark:bg-pink",
    "purple": " bg-purple dark:bg-purple",
    "teal": " bg-teal dark:bg-teal",
    "gray": " bg-gray dark:bg-gray",
}

hover_color = {
    "red": " hover:bg-red hover:dark:bg-red",
    "green": " hover:bg-green hover:dark:bg-green",
    "blue": " hover:bg-blue hover:dark:bg-blue",
    "yellow": " hover:bg-yellow hover:dark:bg-yellow",
    "pink": " hover:bg-pink hover:dark:bg-pink",
    "purple": " hover:bg-purple hover:dark:bg-purple",
    "teal": " hover:bg-teal hover:dark:bg-teal",
    "gray": " hover:bg-gray hover:dark:bg-gray",
}

button_color = {
    "green": " button-green dark:button-green",
    "red": " button-red dark:button-red",
}

def option_display(option, color="gray"):
    """
    Hiển thị một nút lựa chọn có màu

    Parameters
    ----------
        `option` : giá trị hiển thị
        `color`  : màu sắc của biểu tượng
    """
    class_name = "inline-block font-semibold leading-normal px-2 py-1 rounded uppercase text-xxs whitespace-nowrap"

    class_name += text_color.get(color)
    class_name += bg_color.get(color)

    return mark_safe(f"<span class='{class_name}'>{option}</span>")

def action_button(label, url, color="gray"):
    """
    Hiển thị một nút hành động có màu và liên kết

    Parameters
    ----------
        `label` : Nhãn hiển thị trên nút
        `url`   : Đường dẫn liên kết khi nhấn nút
        `color` : Màu sắc của nút
    """
    class_name = "align-middle content-center leading-normal font-medium px-3 py-2 rounded"
    class_name += " whitespace-nowrap no-underline w-full lg:w-auto"
    
    class_name += button_color.get(color, text_color["gray"])

    return mark_safe(f"<a href='{url}' class='{class_name}'>{label}</a>")
