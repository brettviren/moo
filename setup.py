import setuptools

setuptools.setup(
    name="moo",
    version="0.1.0",
    author="Brett Viren",
    author_email="brett.viren@gmail.com",
    description="Model oriented objects",
    url="https://brettviren.github.io/moo",
    packages=setuptools.find_packages(),
    python_requires='>=3.5',    # use of typing probably drive this
    install_requires = [
        "click",
        "jsonnet",
        "jinja2",
        "anyconfig",
        "jsonschema",
        "fastjsonschema",
        "jsonpointer",
#        "transitions",
    ],
    entry_points = dict(
        console_scripts = [
            'moo = moo.__main__:main',
        ]
    ),
)

