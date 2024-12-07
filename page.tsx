import Link from 'next/link'

export default function Home() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center animate-fade-in">
      <h1 className="text-4xl md:text-6xl font-bold text-center mb-6 text-gray-800 dark:text-white">
        Welcome to Arch Linux without Beeps
      </h1>
      <p className="text-xl md:text-2xl text-center mb-8 text-gray-600 dark:text-gray-300 max-w-2xl">
        Experience a streamlined Arch Linux installation without the annoying system beeps.
      </p>
      <div className="flex space-x-4">
        <Link 
          href="/download"
          className="bg-primary text-primary-foreground hover:bg-primary/90 px-6 py-3 rounded-md text-lg font-semibold transition-colors"
        >
          Download Now
        </Link>
        <Link 
          href="/docs"
          className="bg-secondary text-secondary-foreground hover:bg-secondary/90 px-6 py-3 rounded-md text-lg font-semibold transition-colors"
        >
          View Docs
        </Link>
      </div>
    </div>
  )
}

