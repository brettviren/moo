import setuptools

setuptools.setup(
    name="moo",
    version="0.0.0",
    author="Brett Viren",
    author_email="brett.viren@gmail.com",
    description="Model oriented objects",
    url="https://brettviren.github.io/moo",
    packages=setuptools.find_packages(),
    python_requires='>=3.3',    # how to know?
    install_requires = [
        "click",
        "jsonnet",
#        "transitions",
    ],
    entry_points = dict(
        console_scripts = [
            'moo = moo.__main__:main',
        ]
    ),
)

