# ============================================
# pizza_shop.tl
# TaskLang++ Sample Program 2
# Automating a pizza shop's nightly operations
# ============================================

# Count how many pizzas were sold today
TASK countPizzas {
    RUN "count_sales.py"
    EVERY DAY AT 22:00
}

# Only bake more dough if we sold a lot (success = sold enough)
TASK prepareDough {
    RUN "dough_recipe.sh"
    AFTER countPizzas
    IF success
}

# Email the owner a nightly sales report
TASK emailOwner {
    RUN "sales_report.py"
    AFTER prepareDough
    IF success
}

# If sales were too low, send a discount SMS to customers
TASK sendDiscountSMS {
    RUN "discount_promo.sh"
    AFTER countPizzas
    IF failure
}

# Clean the ovens every Sunday night no matter what
TASK cleanOvens {
    RUN "oven_clean.sh"
    EVERY WEEK ON SUNDAY AT 23:30
}
