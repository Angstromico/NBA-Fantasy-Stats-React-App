import React, { useEffect } from 'react'
import './ConfirmationModal.css'

export interface ConfirmationModalProps {
  isOpen: boolean
  title: string
  message: string
  details?: string
  confirmText?: string
  cancelText?: string
  tone?: 'warning' | 'danger' | 'info'
  onConfirm: () => void
  onCancel: () => void
}

const ConfirmationModal: React.FC<ConfirmationModalProps> = ({
  isOpen,
  title,
  message,
  details,
  confirmText = 'Confirm',
  cancelText = 'Cancel',
  tone = 'warning',
  onConfirm,
  onCancel,
}) => {
  useEffect(() => {
    if (!isOpen) return

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        onCancel()
      }
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [isOpen, onCancel])

  if (!isOpen) {
    return null
  }

  const getToneIcon = () => {
    switch (tone) {
      case 'danger':
        return '🗑️'
      case 'warning':
        return '⚠️'
      default:
        return 'ℹ️'
    }
  }

  return (
    <div
      className='modal-overlay'
      onClick={onCancel}
      role='dialog'
      aria-modal='true'
      aria-labelledby='modal-title'
    >
      <div
        className={`modal-container glass-card modal-${tone}`}
        onClick={(e) => e.stopPropagation()}
      >
        <div className='modal-header'>
          <span className='modal-icon' aria-hidden='true'>
            {getToneIcon()}
          </span>
          <h3 id='modal-title'>{title}</h3>
        </div>

        <div className='modal-body'>
          <p className='modal-message'>{message}</p>
          {details && (
            <div className='modal-details'>
              <p>{details}</p>
            </div>
          )}
        </div>

        <div className='modal-actions'>
          <button
            type='button'
            className='modal-btn modal-btn-cancel'
            onClick={onCancel}
          >
            {cancelText}
          </button>
          <button
            type='button'
            className={`modal-btn modal-btn-confirm modal-btn-${tone}`}
            onClick={onConfirm}
          >
            {confirmText}
          </button>
        </div>
      </div>
    </div>
  )
}

export default ConfirmationModal
