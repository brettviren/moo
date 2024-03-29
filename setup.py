import setuptools

ver_globals = {}
with open("moo/version.py") as fp:
    exec(fp.read(), ver_globals)
version = ver_globals["version"]

setuptools.setup(
    name="moo",
    version=version,
    author="Brett Viren",
    author_email="brett.viren@gmail.com",
    description="Model oriented objects",
    url="https://brettviren.github.io/moo",
    packages=setuptools.find_packages(),
    python_requires='>=3.5',    # use of typing probably drive this
    install_requires=[
        "click",
        #"jsonnet>=0.16.0",
        "gojsonnet>=0.20.0",
        "jinja2",
        "anyconfig",
        "jsonschema",
        "fastjsonschema",
        "jsonpointer",
        "numpy",
        "openpyxl",             # make optional?
#        "transitions",
    ],
    entry_points = dict(
        console_scripts = [
            'moo = moo.__main__:main',
        ]
    ),
    include_package_data=True,
)

