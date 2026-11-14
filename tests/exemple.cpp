class MyClass
{
    public:
    MyClass() = default;
    MyClass(const MyClass& /*unused*/) = default;
    MyClass& operator=(const MyClass& /*unused*/) = default;
};