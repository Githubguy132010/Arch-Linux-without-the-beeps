
export default function AboutPage() {
  return (
    <div className="container mx-auto px-4 py-16 animate-fade-in">
      <h1 className="text-4xl md:text-5xl font-bold text-center mb-8 text-gray-800 dark:text-white">
        About Arch Linux without Beeps
      </h1>
      <div className="max-w-3xl mx-auto bg-white dark:bg-gray-800 rounded-lg shadow-lg p-8">
        <p className="text-lg mb-6 text-gray-600 dark:text-gray-300">
          This project was created to help users install Arch Linux without the annoying beeps that can occur during the installation process. It aims to provide a smoother and more pleasant installation experience.
        </p>
        <h2 className="text-2xl font-bold mb-4 text-gray-800 dark:text-white">About the Author</h2>
        <div className="flex items-center mb-6">
          <div>
            <h3 className="text-xl font-semibold text-gray-800 dark:text-white">Thomas Brugman</h3>
            <p className="text-gray-600 dark:text-gray-300">Developer & Linux Enthusiast</p>
          </div>
        </div>
        <p className="text-gray-600 dark:text-gray-300 mb-4">
          Hi, I'm Thomas Brugman. I live in Gouda (Netherlands) and have a keen interest in computers and laptops. I enjoy testing new operating systems and reporting bugs. I'm currently learning YAML and Bash, and I already have some experience with both. I use VS Code as my development environment and am familiar with some fundamental programming concepts.
        </p>
        <p className="text-gray-600 dark:text-gray-300">
          I'm working on the 'Arch-Linux-without-the-beeps' project, which ensures that the system does not produce beep sounds during installation and builds ISO files locally using Docker. I prefer using sudo in scripts and am open to feedback and new features for my project.
        </p>
      </div>
    </div>
  )
}

